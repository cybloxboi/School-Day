const { onSchedule } = require("firebase-functions/v2/scheduler");
const { setGlobalOptions } = require("firebase-functions/v2");
const { DateTime } = require("luxon");
const { initializeApp } = require("firebase-admin/app");
const admin = require("firebase-admin");
const { onCall } = require("firebase-functions/v2/https");
const { onRequest } = require("firebase-functions/v2/https")
const { v4: uuidv4 } = require("uuid");

initializeApp();

setGlobalOptions({
  region: "asia-southeast1",
  timeoutSeconds: 60,
  memory: "256MiB",
});

const NOTIFICATION_TITLE = "⏰ เตรียมเข้าเรียน!";
const NOTIFICATION_BODY = (slot) =>
  `${slot.title || "ไม่ระบุ"} เริ่มเวลา ${slot.startTime.hour}:${String(
    slot.startTime.minute
  ).padStart(2, "0")} - ${slot.endTime.hour}:${String(slot.endTime.minute).padStart(
    2,
    "0"
  )} ที่ ${slot.location} โดย ${slot.professor}`;
const SCHEDULE_DATA_TYPE = "class";

const TODO_NOTIFICATION_TITLE = "📌 ถึงกำหนดการแล้ว!";
const TODO_NOTIFICATION_BODY = (title) => `${title || "มีงานที่ต้องทำ"}`;
const TODO_DATA_TYPE = "task";

exports.notifyTodo = onSchedule(
  { schedule: "* * * * *", timeZone: "Asia/Bangkok" },
  async () => {
    const now = DateTime.now().setZone("Asia/Bangkok");
    console.log(`🕒 Running notifyTodo at: ${now.toISOTime()}`);

    const usersSnapshot = await admin.firestore().collection("Users")
      .where("isNotifyTodos", "==", true)
      .get();

    const userProcessingPromises = usersSnapshot.docs.map(async (userDoc) => {
      const email = userDoc.id;
      const userData = userDoc.data();
      let tokens = userData.tokens || [];

      if (tokens.length === 0) return;

      const todosSnapshot = await admin.firestore().collection("Users").doc(email).collection("Todos").get();

      const messages = [];

      for (const categoryDoc of todosSnapshot.docs) {
        const todos = categoryDoc.data().todos || [];

        for (const todo of todos) {
          if (!todo.selectedDate || todo.isDone) continue;

          const selectedDate = DateTime.fromISO(todo.selectedDate, { zone: "Asia/Bangkok" });
          const targetDateTime = todo.alarmTime
            ? selectedDate.set({ hour: todo.alarmTime.hour, minute: todo.alarmTime.minute })
            : selectedDate.set({ hour: 8, minute: 0 });

          const shouldNotify =
            now.toFormat("yyyy-MM-dd") === targetDateTime.toFormat("yyyy-MM-dd") &&
            now.hour === targetDateTime.hour &&
            now.minute === targetDateTime.minute;

          if (shouldNotify) {
            messages.push({
              notification: {
                title: TODO_NOTIFICATION_TITLE,
                body: TODO_NOTIFICATION_BODY(todo.title),
              },
              data: {
                type: TODO_DATA_TYPE,
                todoId: todo.id,
                categoryId: categoryDoc.id,
              },
            });
          }
        }
      }

      const failedTokens = [];

      for (const msg of messages) {
        for (const token of tokens) {
          try {
            await admin.messaging().send({
              token,
              ...msg,
              android: {
                priority: "high",
                notification: {
                  channelId: "notify_task_channel",
                },
              },
              apns: {
                payload: {
                  aps: {
                    contentAvailable: true,
                    alert: {
                      title: msg.notification.title,
                      body: msg.notification.body,
                    },
                    sound: "default",
                  },
                },
                headers: {
                  "apns-priority": "10",
                },
              },
              webpush: {
                headers: {
                  Urgency: "high",
                },
              },
            });
            console.log(`✅ Sent todo to ${token}`);
          } catch (err) {
            console.error(`❌ Failed todo: ${token}`, err);
            failedTokens.push(token);
          }
        }
      }

      if (failedTokens.length > 0) {
        tokens = tokens.filter((t) => !failedTokens.includes(t));
        await admin.firestore().collection("Users").doc(email).update({ tokens });
      }
    });

    await Promise.all(userProcessingPromises);
    return null;
  }
);

exports.notifyCurrentTimetable = onSchedule(
  { schedule: "* * * * *", timeZone: "Asia/Bangkok" },
  async () => {
    const now = DateTime.now().setZone("Asia/Bangkok");
    const currentMinutes = now.hour * 60 + now.minute;

    const usersSnapshot = await admin.firestore().collection("Users")
      .where("isNotifyTimetable", "==", true)
      .get();

    const userProcessingPromises = usersSnapshot.docs.map(async (userDoc) => {
      const email = userDoc.id;
      const userData = userDoc.data();
      let tokens = userData.tokens || [];
      const todaySlots = userData.todaySlots || [];

      if (tokens.length === 0 || todaySlots.length === 0) return;

      const slotsToNotify = todaySlots.filter((slot) => {
        if (!slot.isNotify) return false;
        const start = slot.startTime?.hour * 60 + slot.startTime?.minute;
        const before = (slot.notifyTime?.hour || 0) * 60 + (slot.notifyTime?.minute || 0);
        return start - before === currentMinutes;
      });

      if (slotsToNotify.length === 0) return;

      const failedTokens = [];

      for (const slot of slotsToNotify) {
        const msg = {
          notification: {
            title: NOTIFICATION_TITLE,
            body: NOTIFICATION_BODY(slot),
          },
          data: { type: SCHEDULE_DATA_TYPE },
        };

        for (const token of tokens) {
          try {
            await admin.messaging().send({
              token,
              ...msg,
              android: {
                priority: "high",
                notification: {
                  channelId: "notify_class_time_channel",
                },
              },
              apns: {
                payload: {
                  aps: {
                    contentAvailable: true,
                    alert: {
                      title: msg.notification.title,
                      body: msg.notification.body,
                    },
                    sound: "default",
                  },
                },
                headers: {
                  "apns-priority": "10",
                },
              },
              webpush: {
                headers: {
                  Urgency: "high",
                },
              },
            });
            console.log(`✅ Sent timetable to ${token}`);
          } catch (err) {
            console.error(`❌ Failed timetable: ${token}`, err);
            failedTokens.push(token);
          }
        }
      }

      if (failedTokens.length > 0) {
        tokens = tokens.filter((t) => !failedTokens.includes(t));
        await admin.firestore().collection("Users").doc(email).update({ tokens });
      }

      const nextNotifyMinutes = todaySlots
        .map((slot) => {
          if (!slot.isNotify) return null;
          const start = slot.startTime?.hour * 60 + slot.startTime?.minute;
          const before = (slot.notifyTime?.hour || 0) * 60 + (slot.notifyTime?.minute || 0);
          const notifyAt = start - before;
          return notifyAt > currentMinutes ? notifyAt : null;
        })
        .filter((m) => m !== null)
        .sort()[0];

      await admin.firestore().collection("Users").doc(email).update({
        hasTodayNotification: !!nextNotifyMinutes,
        nextNotificationMinutes: nextNotifyMinutes || admin.firestore.FieldValue.delete(),
      });
    });

    await Promise.all(userProcessingPromises);
    return null;
  }
);

exports.updateTodayNotificationData = onSchedule(
  {
    schedule: "0 0 * * *",
    timeZone: "Asia/Bangkok",
  },
  async () => {
    const db = admin.firestore();
    const now = DateTime.now().setZone("Asia/Bangkok");
    const currentDayIndex = (now.weekday + 6) % 7;

    const usersSnapshot = await db.collection("Users").get();

    const updatePromises = usersSnapshot.docs.map(async (userDoc) => {
      const email = userDoc.id;

      const timetablesSnapshot = await db
        .collection("Users")
        .doc(email)
        .collection("Timetables")
        .get();

      let todayLessons = [];

      timetablesSnapshot.forEach((ttDoc) => {
        const ttData = ttDoc.data();
        const days = ttData.days || {};
        const dayData = days[currentDayIndex] || [];
        todayLessons = todayLessons.concat(dayData);
      });

      const notifySlots = todayLessons.filter((slot) => slot.isNotify === true);

      const nowMinutes = now.hour * 60 + now.minute;
      const nextNotifyMinutes = notifySlots
        .map((slot) => {
          const start = slot.startTime?.hour * 60 + slot.startTime?.minute;
          const before = (slot.notifyTime?.hour || 0) * 60 + (slot.notifyTime?.minute || 0);
          const notifyAt = start - before;
          return notifyAt > nowMinutes ? notifyAt : null;
        })
        .filter((m) => m !== null)
        .sort((a, b) => a - b)[0];

      await db.collection("Users").doc(email).update({
        todaySlots: todayLessons,
        hasTodayNotification: notifySlots.length > 0,
        nextNotificationMinutes: nextNotifyMinutes || admin.firestore.FieldValue.delete(),
      });
    });

    await Promise.all(updatePromises);
    console.log(`✅ Updated todaySlots for ${usersSnapshot.size} users on dayIndex=${currentDayIndex}`);
    return null;
  }
);

exports.sharePage = onRequest(async (req, res) => {
  const shareId = req.path.split("/").pop();

  try {
    const snap = await admin.firestore().collection("SharedLinks").doc(shareId).get();
    if (!snap.exists) {
      return res.status(404).send("Not Found");
    }

    const data = snap.data();
    const title = data.type === "timetable" ? "แขร์ตารางเรียน" : "แชร์หมวดหมู่งาน";
    const description = `แชร์ข้อมูลโดย ${data.owner}`;
    const image = "https://raw.githubusercontent.com/cybloxboi/School-Day/refs/heads/main/assets/images/app_thumbnail.png"; // เปลี่ยนเป็นภาพจริง

    const html = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta property="og:title" content="${title}" />
  <meta property="og:description" content="${description}" />
  <meta property="og:image" content="${image}" />
  <meta property="og:url" content="https://school-day-a1e87.web.app/share/${shareId}" />
  <meta name="twitter:card" content="summary_large_image">
</head>
<body>
  <script>
    // redirect ไปแอป Flutter Web
    window.location.href = "https://school-day-a1e87.web.app/app/share/${shareId}";
  </script>
</body>
</html>
`;
    res.status(200).send(html);
  } catch (err) {
    res.status(500).send("Server Error");
  }
});

