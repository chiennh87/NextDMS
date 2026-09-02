// ==================== STATE ====================
let state={pin:'',forgotEmail:'',otp:'',otpCooldown:0,otpTimer:null,resendTimer:null,authenticated:false};
const MOCK_OTP='123456';

// ==================== HELPERS ====================
function showScreen(id){document.querySelectorAll('.screen').forEach(s=>s.classList.remove('active'));document.getElementById(id).classList.add('active')}
function showToast(msg,duration=2500){const t=document.getElementById('toast');t.textContent=msg;t.classList.add('show');clearTimeout(t._tid);t._tid=setTimeout(()=>t.classList.remove('show'),duration)}
function togglePassword(id){const i=document.getElementById(id);i.type=i.type==='password'?'text':'password'}
function switchLoginTab(t){document.querySelectorAll('.tab-btn').forEach(b=>b.classList.toggle('active',b.dataset.tab===t));document.getElementById('onlineForm').style.display=t==='online'?'block':'none';document.getElementById('offlineForm').style.display=t==='offline'?'block':'none'}
function updateClock(){const d=new Date();document.getElementById('time').textContent=d.toTimeString().slice(0,5)}
setInterval(updateClock,1000);updateClock();

// ==================== LOGIN ====================
function handleOnlineLogin(e){e.preventDefault();const btn=document.getElementById('loginBtn');btn.querySelector('.btn-text').style.display='none';btn.querySelector('.btn-loader').style.display='inline';btn.disabled=true;
setTimeout(()=>{btn.querySelector('.btn-text').style.display='inline';btn.querySelector('.btn-loader').style.display='none';btn.disabled=false;state.authenticated=true;showScreen('homeScreen');showToast('Đăng nhập thành công!')},1200)}

function pinKey(d){if(state.pin.length<6)state.pin+=d;updatePin();if(state.pin.length===6)setTimeout(()=>{if(state.pin==='123456'){state.authenticated=true;showScreen('homeScreen');showToast('Đăng nhập offline thành công!')}else{showToast('Sai PIN. Mặc định: 123456');pinClear()}},200)}
function pinClear(){state.pin='';updatePin()}
function updatePin(){document.querySelectorAll('.pin-dot').forEach((d,i)=>d.classList.toggle('filled',i<state.pin.length))}
function handleOfflineLogin(e){e.preventDefault();if(state.pin.length!==6){showToast('Nhập đủ 6 số PIN');return}if(state.pin==='123456'){state.authenticated=true;showScreen('homeScreen');showToast('Offline OK!')}else showToast('Sai PIN')}

// ==================== FORGOT PASSWORD ====================
function goToStep(n){document.querySelectorAll('.step-content').forEach((s,i)=>s.classList.toggle('active',i===n-1));for(let i=1;i<=3;i++){const step=document.getElementById('step'+i);const line=document.getElementById('line'+i);step.classList.toggle('active',i===n);step.classList.toggle('done',i<n);if(line)line.classList.toggle('active',i<n)}}

function requestOTP(){const email=document.getElementById('forgotEmail').value.trim();if(!email||!email.includes('@')){showToast('Email không hợp lệ');return}
state.forgotEmail=email;document.getElementById('sentEmail').textContent=email;showToast('OTP đã gửi đến '+email+' (mock: 123456)');goToStep(2);startCooldown();document.querySelectorAll('.otp-box').forEach(b=>b.value='');state.otp='';document.querySelector('.otp-box').focus()}

function verifyOTP(){const boxes=document.querySelectorAll('.otp-box');const otp=Array.from(boxes).map(b=>b.value).join('');if(otp.length!==6){showToast('Nhập đủ 6 số OTP');return}
if(otp===MOCK_OTP){showToast('OTP hợp lệ!');goToStep(3);clearInterval(state.otpTimer);clearTimeout(state.resendTimer)}else showToast('OTP sai. Thử lại 123456')}

function resendOTP(){if(state.otpCooldown>0)return;state.otpCooldown=60;showToast('Đã gửi lại OTP (mock: 123456)');startCooldown()}

function startCooldown(){const btn=document.getElementById('resendBtn');btn.disabled=true;state.otpCooldown=60;document.getElementById('countdown').textContent=state.otpCooldown;state.otpTimer=setInterval(()=>{state.otpCooldown--;document.getElementById('countdown').textContent=state.otpCooldown;if(state.otpCooldown<=0){clearInterval(state.otpTimer);btn.disabled=false;document.getElementById('countdown').textContent='0'}},1000)}

function checkStrength(){const p=document.getElementById('newPassword').value;const segments=document.querySelectorAll('.strength-segment');const label=document.getElementById('strengthLabel');let s=0;if(p.length>=8)s++;if(/[A-Z]/.test(p))s++;if(/[0-9]/.test(p))s++;if(/[^A-Za-z0-9]/.test(p))s++;const colors=['#e0e0e0','#dc3545','#ff9800','#ffc107','#4caf50'];const labels=['Nhập mật khẩu','Yếu','Trung bình','Khá','Mạnh'];segments.forEach((seg,i)=>seg.style.background=i<s?colors[s]:'#e0e0e0');label.textContent=p?labels[s]:'';label.style.color=colors[s]}

function checkMatch(){const p1=document.getElementById('newPassword').value;const p2=document.getElementById('confirmPassword').value;const hint=document.getElementById('matchHint');if(p2.length>0&&p1!==p2)hint.style.display='block';else hint.style.display='none'}

function resetPassword(){const p1=document.getElementById('newPassword').value;const p2=document.getElementById('confirmPassword').value;if(p1.length<8){showToast('Mật khẩu tối thiểu 8 ký tự');return}if(p1!==p2){showToast('Mật khẩu không khớp');return}
const btn=document.getElementById('resetBtn');btn.disabled=true;btn.textContent='Đang xử lý...';setTimeout(()=>{btn.disabled=false;btn.textContent='Đặt Lại Mật Khẩu';document.getElementById('forgotScreen').innerHTML=`<div class=success-content><div class=success-icon>✅</div><h2>Thành công!</h2><p class=muted>Mật khẩu đã được đặt lại cho ${state.forgotEmail}</p><br><button class=btn-primary onclick=showScreen('loginScreen');location.reload()>Quay lại Đăng Nhập</button></div>`},1500)}

// ==================== OTP BOX NAVIGATION ====================
document.addEventListener('DOMContentLoaded',()=>{const boxes=document.querySelectorAll('.otp-box');boxes.forEach((box,i)=>{box.addEventListener('input',(e)=>{const v=e.target.value.replace(/\D/g,'');e.target.value=v;if(v&&i<5)boxes[i+1].focus()});box.addEventListener('keydown',(e)=>{if(e.key==='Backspace'&&!e.target.value&&i>0)boxes[i-1].focus()})})});

// ==================== LOGOUT ====================
function confirmLogout(all){document.getElementById('modalTitle').textContent=all?'Đăng xuất khỏi tất cả thiết bị?':'Đăng xuất?';document.getElementById('modalMessage').textContent=all?'Bạn sẽ bị đăng xuất khỏi TẤT CẢ thiết bị đang đăng nhập.':'Bạn có chắc muốn đăng xuất khỏi thiết bị này?';const conf=document.getElementById('modalConfirm');conf.textContent=all?'Đăng xuất tất cả':'Đăng xuất';conf.onclick=()=>{closeModal();performLogout(all)};document.getElementById('modal').classList.add('show')}
function closeModal(){document.getElementById('modal').classList.remove('show')}
function performLogout(all){showToast(all?'Đã đăng xuất khỏi tất cả thiết bị':'Đã đăng xuất',2000);state.authenticated=false;setTimeout(()=>{pinClear();document.querySelectorAll('.otp-box').forEach(b=>b.value='');state.otp='';showScreen('loginScreen')},800)}
