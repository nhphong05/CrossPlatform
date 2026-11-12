const express = require('express');
const { getLecturerCollection } = require('./db');

const router = express.Router();
const allowedFields = ['IDGV', 'Fullname', 'Image', 'SumClass'];
const createFields = ['Fullname', 'Image', 'SumClass'];

function validateLecturer(body, { requireId = true } = {}) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return { error: 'Dữ liệu giảng viên không hợp lệ.' };
  }

  const keys = Object.keys(body).sort();
  const expectedFields = requireId ? allowedFields : createFields;
  if (
    keys.length !== expectedFields.length ||
    !expectedFields.every((field) => keys.includes(field))
  ) {
    return {
      error: requireId
        ? 'Chỉ chấp nhận IDGV, Fullname, Image và SumClass.'
        : 'Chỉ chấp nhận Fullname, Image và SumClass.',
    };
  }

  const IDGV = typeof body.IDGV === 'string' ? body.IDGV.trim() : '';
  const Fullname =
    typeof body.Fullname === 'string' ? body.Fullname.trim() : '';
  const Image = typeof body.Image === 'string' ? body.Image : '';
  const SumClass = body.SumClass;

  if (requireId && (!IDGV || IDGV.length > 50)) {
    return { error: 'IDGV là bắt buộc và tối đa 50 ký tự.' };
  }
  if (!Fullname || Fullname.length > 150) {
    return { error: 'Fullname là bắt buộc và tối đa 150 ký tự.' };
  }
  if (
    !Image ||
    Image.length > 7_000_000 ||
    !(/^(data:image\/(jpeg|png|webp|gif);base64,|https?:\/\/)/i.test(Image))
  ) {
    return { error: 'Image phải là ảnh JPG, PNG, WEBP hoặc GIF hợp lệ.' };
  }
  if (
    !Number.isSafeInteger(SumClass) ||
    SumClass < 0 ||
    SumClass > 100000
  ) {
    return { error: 'SumClass phải là số nguyên từ 0 đến 100000.' };
  }

  return {
    value: {
      ...(requireId ? { IDGV } : {}),
      Fullname,
      Image,
      SumClass,
    },
  };
}

function nextLecturerId(ids) {
  const maxNumber = ids.reduce((max, id) => {
    const match = /^(?:GV)?(\d+)$/i.exec(id);
    if (!match) return max;
    const number = Number(match[1]);
    return Number.isSafeInteger(number) ? Math.max(max, number) : max;
  }, 0);

  if (maxNumber === Number.MAX_SAFE_INTEGER) {
    throw new Error('Không thể tạo thêm mã giảng viên.');
  }
  return `GV${String(maxNumber + 1).padStart(3, '0')}`;
}

router.get('/', async (request, response, next) => {
  try {
    const lecturers = await getLecturerCollection()
      .find({}, { projection: { _id: 0 } })
      .sort({ Fullname: 1 })
      .toArray();
    response.json(lecturers);
  } catch (error) {
    next(error);
  }
});

router.post('/', async (request, response, next) => {
  const validation = validateLecturer(request.body, { requireId: false });
  if (validation.error) {
    return response.status(400).json({ error: validation.error });
  }

  try {
    const collection = getLecturerCollection();
    while (true) {
      const ids = await collection
        .find(
          { IDGV: /^(?:GV)?\d+$/i },
          { projection: { IDGV: 1, _id: 0 } },
        )
        .map((lecturer) => lecturer.IDGV)
        .toArray();
      const lecturer = {
        ...validation.value,
        IDGV: nextLecturerId(ids),
      };
      try {
        await collection.insertOne(lecturer);
        return response.status(201).json(lecturer);
      } catch (error) {
        if (error.code !== 11000) throw error;
      }
    }
  } catch (error) {
    next(error);
  }
});

router.put('/:id', async (request, response, next) => {
  const validation = validateLecturer(request.body);
  if (validation.error) {
    return response.status(400).json({ error: validation.error });
  }
  if (validation.value.IDGV !== request.params.id) {
    return response.status(400).json({ error: 'Không thể thay đổi IDGV.' });
  }

  try {
    const result = await getLecturerCollection().updateOne(
      { IDGV: request.params.id },
      { $set: validation.value },
    );
    if (result.matchedCount === 0) {
      return response.status(404).json({ error: 'Không tìm thấy giảng viên.' });
    }
    response.json(validation.value);
  } catch (error) {
    next(error);
  }
});

router.delete('/:id', async (request, response, next) => {
  try {
    const result = await getLecturerCollection().deleteOne({
      IDGV: request.params.id,
    });
    if (result.deletedCount === 0) {
      return response.status(404).json({ error: 'Không tìm thấy giảng viên.' });
    }
    response.status(204).end();
  } catch (error) {
    next(error);
  }
});

module.exports = { router, validateLecturer, nextLecturerId };
