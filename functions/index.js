const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const NOTIFICATION_TITLE = "⏰ เตรียมเข้าเรียน!";
const NOTIFICATION_BODY = (slot) =>
  `${slot.title || "ไม่ระบุ"} เริ่มเวลา ${slot.startTime.hour}:${String(
    slot.startTime.minute
  ).padStart(2, "0")} - ${slot.endTime.hour}:${String(slot.endTime.minute).padStart(
    2,
    "0"
  )} ที่ ${slot.location} โดย ${slot.professor}`;
const SCHEDULE_DATA_TYPE = "schedule";

exports.notifyCurrentTimetable = functions.pubsub
  .schedule("* * * * *")
  .timeZone("Asia/Bangkok")
  .onRun(async () => {
    const { DateTime } = require("luxon");

    const now = DateTime.now().setZone("Asia/Bangkok");
    const currentDay = (now.weekday + 6) % 7;
    const currentMinutes = now.hour * 60 + now.minute;

    console.log("🔍 ฟังก์ชัน notifyCurrentTimetable ถูกเรียกแล้ว");
    console.log(`⏰ วันที่ ${currentDay}, นาทีที่ ${currentMinutes}`);

    const usersSnapshot = await admin.firestore().collection("Users")
      .where("hasTodayNotification", "==", true)
      .where("nextNotificationMinutes", "==", currentMinutes)
      .get();

    console.log(`👤 พบผู้ใช้ทั้งหมด: ${usersSnapshot.size}`);

    const userProcessingPromises = usersSnapshot.docs.map(async (userDoc) => {
      const email = userDoc.id;
      const userData = userDoc.data();
      const timetableId = userData.currentTimetableID;
      const tokens = userData.tokens || [];
      const todaySlots = userData.todaySlots || [];

      if (!timetableId || tokens.length === 0 || todaySlots.length === 0) {
        console.log(`⛔ ข้าม ${email} เพราะไม่มี timetableId หรือ token หรือ slot`);
        return;
      }

      const timetableDocRef = admin.firestore()
        .collection("Users")
        .doc(email)
        .collection("Timetables")
        .doc(timetableId);

      const timetableDoc = await timetableDocRef.get();
      if (!timetableDoc.exists) {
        console.log(`⚠️ ${email} ไม่มี Timetable ID: ${timetableId}`);
        return;
      }

      const slotToNotify = todaySlots.find((slot) => {
        if (!slot.isNotify) return false;
        const startMinutes = slot.startTime.hour * 60 + slot.startTime.minute;
        const notifyBefore = (slot.notifyTime?.hour || 0) * 60 + (slot.notifyTime?.minute || 0);
        const notifyAt = startMinutes - notifyBefore;
        return notifyAt === currentMinutes;
      });

      if (!slotToNotify) {
        console.log(`⏳ ${email} ไม่มีคาบที่ต้องแจ้งในนาทีนี้`);

        // หา slot ถัดไป
        const nextNotifyMinutes = todaySlots
          .map((slot) => {
            if (!slot.isNotify) return null;
            const start = slot.startTime.hour * 60 + slot.startTime.minute;
            const before = (slot.notifyTime?.hour || 0) * 60 + (slot.notifyTime?.minute || 0);
            const notifyAt = start - before;
            return notifyAt > currentMinutes ? notifyAt : null;
          })
          .filter((m) => m != null)
          .sort()[0];

        await admin.firestore().collection("Users").doc(email).update({
          hasTodayNotification: !!nextNotifyMinutes,
          nextNotificationMinutes: nextNotifyMinutes || admin.firestore.FieldValue.delete(),
        });

        return;
      }

      // 🔔 ส่งแจ้งเตือน
      const payload = {
        tokens,
        notification: {
          title: NOTIFICATION_TITLE,
          body: NOTIFICATION_BODY(slotToNotify),
        },
        android: {
          priority: "high",
          notification: {
            channel_id: "notify_class_time_channel",
          },
        },
        data: {
          type: SCHEDULE_DATA_TYPE,
        },
      };

      try {
        const response = await admin.messaging().sendEachForMulticast(payload);
        response.responses.forEach((resp, idx) => {
          if (resp.success) {
            console.log(`✅ แจ้งเตือนสำเร็จ: ${tokens[idx]}`);
          } else {
            console.error(`❌ แจ้งไม่สำเร็จ: ${tokens[idx]} | ${resp.error}`);
          }
        });
      } catch (error) {
        console.error(`🚨 ข้อผิดพลาดในการส่งแจ้งเตือน:`, error);
      }

      // หา slot ถัดไปหลังจากแจ้งเสร็จ
      const nextNotifyMinutes = todaySlots
        .map((slot) => {
          if (!slot.isNotify) return null;
          const start = slot.startTime.hour * 60 + slot.startTime.minute;
          const before = (slot.notifyTime?.hour || 0) * 60 + (slot.notifyTime?.minute || 0);
          const notifyAt = start - before;
          return notifyAt > currentMinutes ? notifyAt : null;
        })
        .filter((m) => m != null)
        .sort()[0];

      await admin.firestore().collection("Users").doc(email).update({
        hasTodayNotification: !!nextNotifyMinutes,
        nextNotificationMinutes: nextNotifyMinutes || null,
      });
    });

    await Promise.all(userProcessingPromises);
    return null;
  });
