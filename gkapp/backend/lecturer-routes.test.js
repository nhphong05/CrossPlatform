const assert = require('node:assert/strict');
const test = require('node:test');

const { validateLecturer, nextLecturerId } = require('./lecturer-routes');

const validLecturer = {
  IDGV: ' GV001 ',
  Fullname: ' Nguyễn Minh Anh ',
  Image: 'data:image/png;base64,AA==',
  SumClass: 4,
};

test('accepts and normalizes exactly the four required fields', () => {
  assert.deepEqual(validateLecturer(validLecturer), {
    value: {
      IDGV: 'GV001',
      Fullname: 'Nguyễn Minh Anh',
      Image: 'data:image/png;base64,AA==',
      SumClass: 4,
    },
  });
});

test('validates creation data without a client-provided IDGV', () => {
  const { IDGV, ...createData } = validLecturer;
  assert.deepEqual(validateLecturer(createData, { requireId: false }), {
    value: {
      Fullname: 'Nguyễn Minh Anh',
      Image: 'data:image/png;base64,AA==',
      SumClass: 4,
    },
  });
  assert.match(
    validateLecturer(validLecturer, { requireId: false }).error,
    /Chỉ chấp nhận/,
  );
});

test('generates the next prefixed IDGV from existing numeric IDs', () => {
  assert.equal(nextLecturerId(['GV001', 'gv004', '002', '']), 'GV005');
  assert.equal(nextLecturerId(['002']), 'GV003');
  assert.equal(nextLecturerId([]), 'GV001');
});

test('rejects properties outside the required database schema', () => {
  assert.match(
    validateLecturer({ ...validLecturer, Email: 'lecturer@example.com' }).error,
    /Chỉ chấp nhận/,
  );
});

test('rejects a negative or fractional class count', () => {
  for (const SumClass of [-1, 1.5]) {
    assert.match(
      validateLecturer({ ...validLecturer, SumClass }).error,
      /SumClass/,
    );
  }
});

test('rejects an empty lecturer image', () => {
  assert.match(
    validateLecturer({ ...validLecturer, Image: '' }).error,
    /Image/,
  );
});
