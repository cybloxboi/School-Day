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

exports.notifyCurrentTimetable = onSchedule(
  {
    schedule: "* * * * *",
    timeZone: "Asia/Bangkok",
  },
  async () => {
    const now = DateTime.now().setZone("Asia/Bangkok");
    const currentMinutes = now.hour * 60 + now.minute;

    const usersSnapshot = await admin.firestore().collection("Users")
      .where("isNotifyTimetable", "==", true)
      .where("hasTodayNotification", "==", true)
      .where("nextNotificationMinutes", "==", currentMinutes)
      .get();

    const userProcessingPromises = usersSnapshot.docs.map(async (userDoc) => {
      const email = userDoc.id;
      const userData = userDoc.data();

      if (userData.isNotifyTimetable === false) return;

      const tokens = userData.tokens || [];
      const todaySlots = userData.todaySlots || [];

      if (tokens.length === 0 || todaySlots.length === 0) return;

      const slotToNotify = todaySlots.find((slot) => {
        if (!slot.isNotify) return false;
        const start = slot.startTime?.hour * 60 + slot.startTime?.minute;
        const before = (slot.notifyTime?.hour || 0) * 60 + (slot.notifyTime?.minute || 0);
        return start - before === currentMinutes;
      });

      if (!slotToNotify) {
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
        return;
      }

      for (const token of tokens) {
        const message = {
          token,
          notification: {
            title: NOTIFICATION_TITLE,
            body: NOTIFICATION_BODY(slotToNotify),
          },
          android: {
            notification: {
              channelId: "notify_class_time_channel",
              priority: "high",
            },
          },
          apns: {
            payload: {
              aps: {
                alert: {
                  title: NOTIFICATION_TITLE,
                  body: NOTIFICATION_BODY(slotToNotify),
                },
                sound: "default",
              },
            },
          },
          data: {
            type: SCHEDULE_DATA_TYPE,
          },
        };

        try {
          await admin.messaging().send(message);
        } catch (err) {
          console.error(`❌ ส่งไม่สำเร็จ: ${token}`, err);
        }
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
    const currentDayIndex = (now.weekday + 6) % 7;

    const updatePromises = usersSnapshot.docs.map(async (userDoc) => {
      const email = userDoc.id;
      const userData = userDoc.data();
      const timetableId = userData.currentTimetableID;

      if (!timetableId) return;

      const dayDoc = await db
        .collection("Users")
        .doc(email)
        .collection("Timetables")
        .doc(timetableId)
        .collection("Days")
        .doc(currentDayIndex.toString())
        .get();

      const lessons = dayDoc.exists ? dayDoc.data().lessons || [] : [];
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
