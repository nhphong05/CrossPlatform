const { MongoClient } = require('mongodb');

const databaseName = process.env.MONGODB_DB || 'QLHocPhan';
let client;
let collection;

async function connectDatabase() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    throw new Error('Thiếu MONGODB_URI trong backend/.env.');
  }

  client = new MongoClient(uri, {
    serverSelectionTimeoutMS: 10000,
  });
  await client.connect();
  const database = client.db(databaseName);
  collection = database.collection('GiangVien');
  await collection.createIndex({ IDGV: 1 }, { unique: true });
  return collection;
}

function getLecturerCollection() {
  if (!collection) {
    throw new Error('MongoDB chưa được kết nối.');
  }
  return collection;
}

async function closeDatabase() {
  if (client) {
    await client.close();
  }
}

module.exports = { connectDatabase, getLecturerCollection, closeDatabase };
