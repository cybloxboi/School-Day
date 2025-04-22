const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.notifyCurrentTimetable = functions.pubsub
    .schedule("* * * * *")
    .timeZone("Asia/Bangkok")
    .onRun(async (context) => {
      const {DateTime} = require("luxon");

      const now = DateTime.now().setZone("Asia/Bangkok");
      const currentDay = (now.weekday + 6) % 7;
      const currentMinutes = now.hour * 60 + now.minute;

      const usersSnapshot = await admin.firestore().collection("Users").get();

      console.log("🔍 ฟังก์ชัน notifyCurrentTimetable ถูกเรียกแล้ว");
      console.log(`👤 พบผู้ใช้ทั้งหมด: ${usersSnapshot.size}`);

      for (const userDoc of usersSnapshot.docs) {
        const email = userDoc.id;
        const userData = userDoc.data();
        const timetableId = userData.currentTimetableID;

        console.log(`➡️ ${email} | currentTimetableId: ${timetableId}`);

        if (!timetableId) {
          console.log(`⚠️ ${email} ไม่มี currentTimetableId`);
          continue;
        }

        const timetableDoc = await admin.firestore()
            .collection("Users")
            .doc(email)
            .collection("Timetables")
            .doc(timetableId)
            .get();

        console.log(
            `📄 ดึง Timetable สำเร็จสำหรับ ${email}: ` +
            `exists=${timetableDoc.exists}`,
        );

        if (!timetableDoc.exists) {
          console.log(`⚠️ ${email} ไม่มี Timetable ID: ${timetableId}`);
          continue;
        }

        const {days = {}} = timetableDoc.data();
        console.log(`📅 days:`, JSON.stringify(days));
        const todaySlots = days[String(currentDay)] || [];

        console.log(
            `📆 ${email} | คาบวันนี้ (${currentDay}): ` +
          `${todaySlots.length} คาบ`,
        );

        for (const slot of todaySlots) {
          if (slot.isNotify === false) {
            console.log(`🔕 ${email} ปิดแจ้งเตือน: ${slot.title}`);
            continue;
          }

          const startTime = slot.startTime;
          const endTime = slot.endTime;
          const notifyTime = slot.notifyTime || {hour: 0, minute: 0};

          if (
            !startTime ||
            typeof startTime.hour !== "number" ||
            typeof startTime.minute !== "number"
          ) {
            console.log(`⚠️ startTime ผิด format สำหรับ ${email}:`, startTime);
            continue;
          }

          const startMinutes = (startTime.hour * 60) + startTime.minute;
          const notifyBefore = (notifyTime.hour * 60) + notifyTime.minute;
          const notifyAt = startMinutes - notifyBefore;

          if (notifyAt != currentMinutes) {
            console.log("ไม่แจ้งเตือน");
            continue;
          }

          const tokenSnap = await admin.firestore()
              .collection("Users")
              .doc(email)
              .collection("Tokens")
              .get();

          const tokens = tokenSnap.docs.map((doc) => doc.id);
          if (tokens.length === 0) {
            console.log(`📭 ${email} ไม่มี token`);
            continue;
          }

          const response = await admin.messaging().sendEachForMulticast({
            tokens: tokens,
            notification: {
              title: "⏰ เตรียมเข้าเรียน!",
              body: `${
                slot.title || "ไม่ระบุ"
              } เริ่มเวลา ${startTime.hour}:${
                String(startTime.minute).padStart(2, "0")
              } - ${endTime.hour}:${
                String(endTime.minute).padStart(2, "0")
              } ที่ ${slot.location} โดย ${slot.professor}`,
            },
            data: {
              type: "schedule",
              timetableId: timetableId,
            },
          });

          response.responses.forEach((resp, idx) => {
            if (resp.success) {
              console.log(`✅ ส่งแจ้งเตือนสำเร็จ: ${tokens[idx]}`);
            } else {
              console.error(`❌ ส่งไม่สำเร็จ: ${tokens[idx]} | ${resp.error}`);
            }
          });
        }
      }

      return null;
    });
