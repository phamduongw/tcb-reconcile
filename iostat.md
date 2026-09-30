# Runbook: đọc I/O của `nvme1n1` bằng `iostat`

## 1. Chạy lệnh

```bash
iostat -tdmxy nvme1n1 1
```

| Thành phần | Tác dụng |
| --- | --- |
| `-t` | In thời điểm lấy mẫu. |
| `-d` | Chỉ in thống kê thiết bị; không in CPU. |
| `-m` | In tốc độ theo MiB/s (tên cột ghi `MB/s`; 1 MiB = 1024 KiB). |
| `-x` | In các chỉ số mở rộng: IOPS, throughput, latency, hàng đợi, `%util`. |
| `-y` | Bỏ báo cáo đầu tiên tính từ lúc khởi động. |
| `nvme1n1` | Chỉ theo dõi thiết bị này. |
| `1` | Lấy một mẫu mỗi giây; `Ctrl+C` để dừng. Thêm `60` cuối lệnh để lấy 60 mẫu. |

Xác nhận đúng ổ bằng `lsblk -o NAME,TYPE,SIZE,MOUNTPOINTS`. Nên đo khi hệ thống có tải.

## 2. Đọc kết quả

Mẫu thực tế từ baseline (một khoảng đo 1 giây):

```text
2026-09-29T23:51:05+0700
Device     r/s    w/s   rMB/s  wMB/s  rrqm/s  wrqm/s  %rrqm  %wrqm  r_await  w_await  aqu-sz  rareq-sz  wareq-sz  svctm  %util
nvme1n1   0.00  556.00  0.00  125.05    0.00    0.00   0.00    0.00     0.00    21.78    12.11      0.00     230.30   1.80  100.00
```

`r` = đọc, `w` = ghi, `/s` = mỗi giây. Các tốc độ và độ trễ là **giá trị trung bình trong khoảng đo**, không phải đỉnh tức thời.

| Cột | Ý nghĩa | Đọc mẫu này |
| --- | --- | --- |
| Thời gian | Thời điểm in báo cáo. | `2026-09-29 23:51:05`, múi giờ `+07:00`. |
| `Device` | Thiết bị được đo. | `nvme1n1`. |
| `r/s` | **IOPS đọc:** yêu cầu đọc hoàn tất mỗi giây ở lớp thiết bị. | `0`: không có lượt đọc được ghi nhận. |
| `w/s` | **IOPS ghi:** yêu cầu ghi hoàn tất mỗi giây. Tổng IOPS đọc + ghi ≈ `r/s + w/s`. | `556`: khoảng **556 IOPS**, hầu hết là ghi. |
| `rMB/s` | **Throughput đọc:** lượng dữ liệu đọc mỗi giây. | `0 MiB/s`. |
| `wMB/s` | **Throughput ghi:** lượng dữ liệu ghi mỗi giây. Tổng đọc + ghi ≈ `rMB/s + wMB/s`. | `125,05 MiB/s`, hầu hết là ghi. |
| `rrqm/s` | Số yêu cầu đọc được gộp mỗi giây trước khi xuống thiết bị. | `0`; không cộng vào `r/s`. |
| `wrqm/s` | Số yêu cầu ghi được gộp mỗi giây. | `0`; không cộng vào `w/s`. |
| `%rrqm` | Tỷ lệ yêu cầu đọc được gộp. | `0%`; không phải mức sử dụng ổ. |
| `%wrqm` | Tỷ lệ yêu cầu ghi được gộp. | `0%`; không phải mức sử dụng ổ. |
| `r_await` | **Latency đọc:** thời gian trung bình để hoàn tất một lượt đọc, gồm chờ hàng đợi và xử lý; đơn vị ms. | `0`: không có lượt đọc để đánh giá latency đọc. |
| `w_await` | **Latency ghi:** tương tự cho một lượt ghi; không phải độ trễ toàn ứng dụng. | Trung bình **21,78 ms/lượt ghi**. |
| `aqu-sz` | Số I/O **chưa hoàn tất trung bình**, gồm đang chờ và đang xử lý. | Khoảng **12,11 I/O** đồng thời chưa hoàn tất. |
| `rareq-sz` | Kích thước trung bình một lượt đọc, KiB/I/O. | `0`: không có lượt đọc để tính. |
| `wareq-sz` | Kích thước trung bình một lượt ghi, KiB/I/O. | **230,30 KiB**; `556 × 230,30 ÷ 1024 ≈ 125 MiB/s`. |
| `svctm` | Ước tính thời gian phục vụ I/O kiểu cũ; không đáng tin trên ổ xử lý song song. | `1,80 ms`: **không** dùng thay cho `w_await`. Bản `iostat` mới có thể bỏ cột này. |
| `%util` | **Utilization:** tỷ lệ thời gian thiết bị có I/O hoạt động. Không phải % hạn mức IOPS/throughput đã dùng. | `100%`: có I/O gần như suốt giây đo; **chưa đủ** để kết luận NVMe/EBS quá tải. |

**Kết luận vận hành:** Mẫu này ghi khoảng **125 MiB/s** ở **556 IOPS**, độ trễ ghi **21,78 ms**. Nếu đây là EBS gp3 mặc định (125 MiB/s, 3.000 IOPS) và **nhiều mẫu liên tiếp** tương tự, nghi ngờ chạm **giới hạn throughput**, không phải IOPS. Đối chiếu cấu hình volume và giới hạn EBS của instance trước khi kết luận; đừng dựa riêng vào `%util`.

**Lưu ý:** Tên cột có thể khác theo phiên bản `sysstat` (ví dụ thêm discard/flush, bỏ `svctm`). Nếu có cả `dm-*` và ổ vật lý, không cộng số liệu hai lớp vì có thể tính trùng I/O.
