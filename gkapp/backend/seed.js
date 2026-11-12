require('dotenv').config();

const sampleLecturers = require('./sample-data.json');
const { closeDatabase, connectDatabase } = require('./db');

async function seed() {
  const lecturers = await connectDatabase();
  for (const lecturer of sampleLecturers) {
    await lecturers.updateOne(
      { IDGV: lecturer.IDGV },
      { $set: lecturer },
      { upsert: true },
    );
  }
  console.log(`Đã nhập ${sampleLecturers.length} giảng viên mẫu.`);
}

seed()
  .catch((error) => {
    console.error(`Không thể nhập dữ liệu mẫu: ${error.message}`);
    process.exitCode = 1;
  })
  .finally(closeDatabase);
