# FIT4110_lab03_postman_mock_testing

**Học phần:** FIT4110 – Dịch vụ kết nối và Công nghệ nền tảng  
**Buổi 3:** Kiểm thử tích hợp với Postman + Mock Server  
**Case study:** Smart Campus Operations Platform  
**Artefact chính:** Postman Collection, Environment mock/local, Newman report, Reliability Checklist

---

## 1. Ý tưởng của lab

Ở **Lab 02**, mỗi nhóm đã thiết kế `openapi.yaml` như một **hợp đồng API**.  
Sang **Lab 03**, hợp đồng đó phải được biến thành **bộ kiểm thử có thể chạy được**.

> Tư duy chính: **API contract không chỉ để đọc, mà phải kiểm chứng được bằng test.**

Lab này mô phỏng tình huống rất thực tế trong hệ thống nhiều nhóm:

- Nhóm **Camera Stream** cần gọi **AI Vision**, nhưng AI Vision chưa code xong.
- Nhóm **Analytics** cần dữ liệu từ IoT, Camera, Core, nhưng các service chưa hoàn thiện.
- Nhóm **Core Business** cần kiểm thử luồng từ Access Gate / AI Vision / IoT, nhưng chưa thể chờ toàn bộ lớp xong code.

Giải pháp là dùng **Mock Server + Postman + Newman**:

1. Provider tạo mock từ `openapi.yaml`.
2. Consumer gọi vào mock để phát triển và kiểm thử sớm.
3. Provider viết Postman Collection để kiểm tra service của mình.
4. Newman chạy collection trên CLI / GitHub Actions để tạo evidence.
5. Test được chạy trên cả 2 môi trường:
   - `mock`: kiểm thử hợp đồng khi service thật chưa xong.
   - `local`: kiểm thử service thật khi nhóm đã code xong.

---

## 2. Mục tiêu học tập

Sau lab này, sinh viên có thể:

- Import OpenAPI vào Postman và tạo collection có cấu trúc rõ ràng.
- Dùng Mock Server để mô phỏng provider API.
- Viết test script bằng `pm.test`, kiểm tra status code, schema cơ bản, auth, dữ liệu biên.
- Tổ chức environment `mock` và `local`.
- Chạy collection bằng Newman và xuất report.
- Thực hiện consumer-side contract smoke test với mock của nhóm khác.
- Nộp đủ evidence theo phong cách repo-based assessment.

---

## 3. Cấu trúc repo

```text
FIT4110_lab03_postman_mock_testing/
├── README.md
├── package.json
├── Makefile
├── contracts/
│   └── iot-ingestion.openapi.yaml
├── postman/
│   ├── collections/
│   │   └── FIT4110_lab03_iot_ingestion.postman_collection.json
│   └── environments/
│       ├── FIT4110_lab03_mock.postman_environment.json
│       └── FIT4110_lab03_local.postman_environment.json
├── mock-data/
│   ├── sensor-reading-valid.json
│   ├── sensor-reading-invalid-missing-device.json
│   └── sensor-reading-boundary.json
├── docs/
│   ├── LAB_GUIDE.md
│   ├── TEAM_TASKS.md
│   ├── CONSUMER_SIDE_TESTING.md
│   └── GITHUB_ACTIONS_GUIDE.md
├── checklists/
│   ├── reliability_checklist.md
│   └── submission_checklist.md
├── templates/
│   ├── test-case-matrix.csv
│   └── consumer-provider-handshake.md
├── scripts/
│   ├── start-prism-mock.sh
│   └── run-newman.sh
├── reports/
│   └── .gitkeep
└── .github/
    └── workflows/
        └── newman.yml
```

---

## 4. Chuẩn bị môi trường

Cài Node.js LTS, sau đó chạy:

```bash
npm install
```

Kiểm tra version:

```bash
npx newman --version
npx prism --version
```

---

## 5. Chạy Mock Server từ OpenAPI

Repo có sẵn contract mẫu cho **IoT Ingestion** tại:

```text
contracts/iot-ingestion.openapi.yaml
```

Chạy mock bằng Prism:

```bash
npm run mock:iot
```

Mock server mặc định chạy tại:

```text
http://localhost:4010
```

Kiểm tra nhanh:

```bash
curl http://localhost:4010/health
```

---

## 6. Chạy Postman Collection bằng Newman

Chạy với môi trường mock:

```bash
npm run test:mock
```

Chạy với môi trường local:

```bash
npm run test:local
```

Sau khi chạy, report được xuất vào thư mục:

```text
reports/
```

---

## 7. Nhiệm vụ của nhóm

Mỗi nhóm cần thay contract mẫu bằng contract của service mình từ Lab 02, sau đó tạo bộ test tương ứng.

Yêu cầu tối thiểu:

| Nhóm | Số test tối thiểu | Bắt buộc có |
|---|---:|---|
| team-iot | 10 | POST reading, latest reading, auth, validation, boundary |
| team-camera | 10 | upload frame, trigger analyze, invalid image, callback/mock AI Vision |
| team-gate | 10 | access event, allow/deny, invalid card, auth |
| team-vision | 10 | detect image, model info, invalid image_url/base64, confidence boundary |
| team-analytics | 10 | ingest event, aggregate metric, missing time range, multi-source smoke |
| team-core | 10 | evaluate sensor/access/detection, policy not found, alert creation |
| team-notify | 10 | send notification, retry, dedupe, invalid channel, upstream alert mock |

Mỗi collection nên có ít nhất 4 nhóm test:

1. `Functional`
2. `Auth`
3. `Negative`
4. `Boundary / Reliability`

---

## 8. Artefact phải nộp

Nộp vào repo nhóm hoặc LMS:

- `postman/collections/<team>.postman_collection.json`
- `postman/environments/<team>_mock.postman_environment.json`
- `postman/environments/<team>_local.postman_environment.json`
- `reports/newman-report.xml` hoặc `reports/newman-report.html`
- `checklists/reliability_checklist.md`
- `templates/test-case-matrix.csv` đã điền
- Biên bản consumer-provider handshake với ít nhất 1 nhóm phụ thuộc

---

## 9. Quy tắc đánh giá 

| Tiêu chí | Điểm |
|---|---:|
| Collection có cấu trúc rõ ràng, dễ đọc | 2.0 |
| Test phủ happy path, auth, negative, boundary | 3.0 |
| Chạy được trên cả mock và local environment | 2.0 |
| Có Newman report / evidence CI | 2.0 |
| Có consumer-side test với mock của nhóm khác | 1.0 |
| Tổng Tổng| 10|
---

## 10. Tinh thần của buổi học

> Sau Buổi 2, chúng ta có **hợp đồng API**.  
> Sau Buổi 3, hợp đồng đó trở thành **bộ kiểm thử**.  
> Từ đây, mỗi lần sửa service, nhóm phải chứng minh: API vẫn đúng hợp đồng, consumer vẫn gọi được, và lỗi được xử lý có kiểm soát.
