WebLab5 - ชุดไฟล์เกมสำหรับเว็บ

เปิดเล่นบนเครื่อง Windows:
1. แตก ZIP ทั้งหมดก่อน (ถ้าได้รับเป็น ZIP)
2. ดับเบิลคลิก Start-WebLab5.cmd (ต้องมี Python 3)
3. เบราว์เซอร์จะเปิด http://127.0.0.1:8000/ โดยอัตโนมัติ หากพอร์ตไม่ว่างจะเลือกพอร์ตอื่น
4. เปิดหน้าต่าง server ค้างไว้ระหว่างเล่น กด Ctrl+C เพื่อปิด
อย่าเปิด index.html หรือ LAB05.html ด้วยการดับเบิลคลิกโดยตรง ให้เข้าผ่าน localhost หรือเว็บโฮสติ้ง

ไฟล์ที่ต้องอยู่ด้วยกัน:
- index.html (หน้าแรก เหมือน LAB05.html)
- LAB05.html (หน้าเกมชื่อเดิม)
- LAB05.js (ตัวโหลดเกม)
- LAB05.wasm (เอนจินเกม)
- LAB05.pck (ข้อมูลเกม ฉาก โมเดล เสียง และสคริปต์ที่ Export แล้ว)
- LAB05.audio.worklet.js และ LAB05.audio.position.worklet.js (ระบบเสียง)
- LAB05.png, LAB05.icon.png, LAB05.apple-touch-icon.png (ภาพโหลดและไอคอน)
ห้ามเปลี่ยนชื่อ LAB05.* แยกกัน เพราะ HTML และตัวโหลดอ้างชื่อเหล่านี้
ไม่ต้องแนบ Assets, Scenes, Scripts, .godot หรือไฟล์ .import สำหรับการเล่นเว็บ

อัป GitHub Pages:
อัปเนื้อหาภายใน WebLab5 ให้ index.html อยู่ที่รากของโฟลเดอร์เผยแพร่ และเปิด Pages ที่ branch/folder นั้น
คงไฟล์ .nojekyll ไว้ด้วย ส่วน serve.py, Start-WebLab5.cmd และ README.txt ไม่จำเป็นต่อเว็บออนไลน์
ใช้เว็บโฮสติ้งผ่าน HTTPS และเบราว์เซอร์ที่รองรับ WebAssembly และ WebGL 2
ชุดนี้ Export แบบไม่ใช้ threads ตามค่าภายใน LAB05.html

ควบคุม: WASD เคลื่อนที่ / เมาส์มอง / Space กระโดด / Esc พัก / R เริ่มใหม่
