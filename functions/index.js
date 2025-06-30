const { onSchedule } = require("firebase-functions/v2/scheduler");
const { setGlobalOptions } = require("firebase-functions/v2");
const { DateTime } = require("luxon");
const { initializeApp } = require("firebase-admin/app");
const admin = require("firebase-admin");

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
const SCHEDULE_DATA_TYPE = "schedule";

const TODO_NOTIFICATION_TITLE = "📌 ถึงกำหนดการแล้ว!";
const TODO_NOTIFICATION_BODY = (title) => `${title || "มีงานที่ต้องทำ"}`;
const TODO_DATA_TYPE = "todo";

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

          const diffInMinutes = now.diff(targetDateTime, "minutes").minutes;
          const shouldNotify = diffInMinutes >= 0 && diffInMinutes < 2;

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
            await admin.messaging().send({ token, ...msg });
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

      // แจ้งเตือนทุก slot ที่ตรงเวลา
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
            await admin.messaging().send({ token, ...msg });
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
    const usersSnapshot = await db.collection("Users").get();
    const now = DateTime.now().setZone("Asia/Bangkok");
    const currentDayIndex = now.weekday - 1; // Luxon: Monday = 1 → index 0

    const updatePromises = usersSnapshot.docs.map(async (userDoc) => {
      const email = userDoc.id;
      const userData = userDoc.data();
      const timetableId = userData.currentTimetableID;

      if (!timetableId) return;

      const timetableDoc = await db
        .collection("Users")
        .doc(email)
        .collection("Timetables")
        .doc(timetableId)
        .get();

      if (!timetableDoc.exists) return;

      const timetableData = timetableDoc.data();
      const days = timetableData.days || [];

      const dayData = days[currentDayIndex] || {};
      const lessons = dayData.lessons || [];
      const notifySlots = lessons.filter((slot) => slot.isNotify === true);

      const nowMinutes = now.hour * 60 + now.minute;
      const nextNotifyMinutes = notifySlots
        .map((slot) => {
          const start = slot.startTime?.hour * 60 + slot.startTime?.minute;
          const before = (slot.notifyTime?.hour || 0) * 60 + (slot.notifyTime?.minute || 0);
          const notifyAt = start - before;
          return notifyAt > nowMinutes ? notifyAt : null;
        })
        .filter((m) => m !== null)
        .sort()[0];

      await db.collection("Users").doc(email).update({
        todaySlots: lessons,
        hasTodayNotification: notifySlots.length > 0,
        nextNotificationMinutes: nextNotifyMinutes || admin.firestore.FieldValue.delete(),
      });
    });

    await Promise.all(updatePromises);
    return null;
  }
);
