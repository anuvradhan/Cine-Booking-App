<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CineBooking | Live Ticket System</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    
    <!-- Firebase SDKs -->
    <script type="module">
        import { initializeApp } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-app.js";
        import { 
            getAuth, onAuthStateChanged, signInAnonymously, signOut,
            createUserWithEmailAndPassword, signInWithEmailAndPassword, sendPasswordResetEmail,
            GoogleAuthProvider, signInWithPopup
        } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-auth.js";
        import { getFirestore, doc, setDoc, getDoc, collection, onSnapshot, updateDoc, arrayUnion } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-firestore.js";

        const firebaseConfig = {
            apiKey: "AIzaSyDz8pc69v5_HMtza-nSf8n-FAUN0d293ZE",
            authDomain: "cinebooking-1efdc.firebaseapp.com",
            projectId: "cinebooking-1efdc",
            storageBucket: "cinebooking-1efdc.firebasestorage.app",
            messagingSenderId: "1094503863076",
            appId: "1:1094503863076:web:7e2c88cb32c62f20f059b1"
        };

        const app = initializeApp(firebaseConfig);
        const auth = getAuth(app);
        const db = getFirestore(app);
        const appId = 'cinebooking-1efdc-live'; 

        window.db = db;
        window.auth = auth;
        window.appId = appId;
        window.googleProvider = new GoogleAuthProvider();
        
        window.fs = { 
            doc, setDoc, getDoc, collection, onSnapshot, updateDoc, arrayUnion, signOut,
            createUserWithEmailAndPassword, signInWithEmailAndPassword, sendPasswordResetEmail,
            signInWithPopup
        };

        onAuthStateChanged(auth, async (user) => {
            // Reset amount selection on account switch
            state.selectedSeats = [];
            
            if (user && !user.isAnonymous) {
                const profileRef = doc(db, 'artifacts', appId, 'users', user.uid, 'profile', 'data');
                const profileSnap = await getDoc(profileRef);
                
                if (profileSnap.exists()) {
                    state.isAuthenticated = true;
                    state.userProfile = profileSnap.data();
                } else {
                    const initialProfile = {
                        name: user.displayName || 'User',
                        email: user.email,
                        phone: '+91 79813 38737'
                    };
                    await setDoc(profileRef, initialProfile);
                    state.isAuthenticated = true;
                    state.userProfile = initialProfile;
                }

                const historyRef = doc(db, 'artifacts', appId, 'users', user.uid, 'history', 'list');
                const historySnap = await getDoc(historyRef);
                if (historySnap.exists()) {
                    state.bookingHistory = historySnap.data().bookings || [];
                }
                
                if (state.selectedSeats.length > 0) {
                    navigate('checkout');
                } else if (state.step === 'login') {
                    navigate('home');
                }
            } else {
                state.isAuthenticated = false;
                state.userProfile = null;
                state.bookingHistory = [];
            }
            render();
        });
    </script>

    <style>
        .no-scrollbar::-webkit-scrollbar { display: none; }
        .no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
        .seat { transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1); }
        .seat:hover:not(.occupied) { transform: scale(1.2); z-index: 10; }
        .seat.occupied { background-color: #e5e7eb; color: #9ca3af; cursor: not-allowed; border-color: #d1d5db; opacity: 0.6; }
        .auth-card { animation: slideUp 0.4s cubic-bezier(0.16, 1, 0.3, 1); }
        @keyframes slideUp { from { transform: translateY(20px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
        .nav-item { flex: 1; display: flex; flex-direction: column; align-items: center; cursor: pointer; transition: color 0.2s; }
        .nav-item i { font-size: 20px; margin-bottom: 4px; }
        .nav-item span { font-size: 10px; font-weight: 600; }
        .nav-active { color: #f84464; }
        .nav-inactive { color: #9ca3af; }
        
        /* Ticket Cut Design */
        .ticket-cut { position: relative; }
        .ticket-cut::before, .ticket-cut::after {
            content: '';
            position: absolute;
            width: 24px;
            height: 24px;
            background: rgba(0,0,0,0.8);
            border-radius: 50%;
            top: 50%;
            transform: translateY(-50%);
            z-index: 10;
        }
        .ticket-cut::before { left: -12px; }
        .ticket-cut::after { right: -12px; }
    </style>
</head>
<body class="bg-gray-50 text-gray-900 font-sans selection:bg-rose-100">

    <div id="navbar-container"></div>
    <div id="content-container" class="max-w-7xl mx-auto px-4 lg:px-8 py-8 pb-32"></div>
    <div id="mobile-nav-container"></div>

    <!-- Modals -->
    <div id="locationModal" class="fixed inset-0 bg-black/60 z-[100] hidden items-center justify-center p-4 backdrop-blur-sm">
        <div class="bg-white w-full max-w-md rounded-2xl overflow-hidden shadow-2xl">
            <div class="p-5 border-b flex justify-between items-center">
                <h3 class="font-bold text-lg">Select Location</h3>
                <i class="fa-solid fa-xmark text-gray-400 cursor-pointer hover:text-rose-500" onclick="toggleLocationModal(false)"></i>
            </div>
            <div id="locationList" class="max-h-[60vh] overflow-y-auto grid grid-cols-1 sm:grid-cols-2"></div>
        </div>
    </div>

    <!-- Professional Ticket Modal -->
    <div id="ticketModal" class="fixed inset-0 bg-black/80 z-[110] hidden items-center justify-center p-4 backdrop-blur-md overflow-y-auto">
        <div class="w-full max-w-sm relative">
            <button onclick="closeTicketModal()" class="absolute -top-12 right-0 text-white hover:text-rose-400 transition-colors">
                <i class="fa-solid fa-circle-xmark text-3xl"></i>
            </button>
            <div id="ticketDataContainer">
                <!-- Ticket Content Generated Here -->
            </div>
        </div>
    </div>

    <script>
        const state = {
            step: 'home', 
            isAuthenticated: false,
            authMode: 'signin', 
            authMessage: null, 
            movies: [],
            selectedMovie: null,
            selectedTheater: null,
            selectedTime: null,
            selectedDate: null,
            selectedLocation: 'Warangal',
            selectedSeats: [],
            globalBookedSeats: [],
            bookingId: null,
            searchQuery: '',
            userProfile: null,
            bookingHistory: []
        };

        const LOCATIONS = ["Warangal", "Hyderabad", "Jangaon", "Karimnagar", "Khammam", "Siddipet"];
        let currentTheaters = [];

        async function fetchTheatersFromServlet(location) {
            try {
                const response = await fetch('BookingServlet?action=getTheaters&location=' + encodeURIComponent(location));
                currentTheaters = await response.json();
            } catch (err) {
                console.error("Servlet connection failed.", err);
                currentTheaters = [];
            }
        }

        async function getCostFromServlet(numSeats, includeFee = false) {
            try {
                const response = await fetch('BookingServlet', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                    body: `seatCount=${numSeats}&includeFee=${includeFee}`
                });
                return await response.json();
            } catch (err) {
                const ticketTotal = numSeats * 250;
                const gst = ticketTotal * 0.18;
                const fee = includeFee ? (ticketTotal * 0.02) : 0;
                return { total: ticketTotal + gst + fee, gst: gst, fee: fee };
            }
        }

        const getDates = () => {
            const days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
            const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
            return Array.from({length: 7}, (_, i) => {
                const d = new Date(); d.setDate(d.getDate() + i);
                return { id: d.toISOString().split('T')[0], day: days[d.getDay()], dateNum: d.getDate(), month: months[d.getMonth()], full: d.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' }) };
            });
        };
        const availableDates = getDates();

        function isTimePast(timeStr, dateId) {
            const now = new Date();
            const todayId = now.toISOString().split('T')[0];
            if (dateId > todayId) return false;
            if (dateId < todayId) return true;
            const [time, modifier] = timeStr.split(' ');
            let [hours, minutes] = time.split(':').map(Number);
            if (modifier === 'PM' && hours < 12) hours += 12;
            if (modifier === 'AM' && hours === 12) hours = 0;
            const showTimeDate = new Date();
            showTimeDate.setHours(hours, minutes, 0, 0);
            return now > showTimeDate;
        }

        async function fetchMovies(query = "") {
            state.searchQuery = query;
            const fallback = [
                { id: 1, title: 'Biker', rating: 9.3, votes: '8.1K+', genre: 'Action, Drama', director: 'K. Sandeep', image: 'https://images.filmibeat.com/webp/ph-big/2026/04/biker1775038989_0.jpeg' },
                { id: 2, title: 'Raakaasa', rating: 8.7, votes: '6K+', genre: 'Horror', director: 'Vikram K.', image: 'https://filmfreeway-production-storage-01-connector.filmfreeway.com/press_kits/posters/003/293/453/original/0ea2bc5396-poster.jpg?1751545614' },
                { id: 3, title: 'Leader', rating: 9.5, votes: '12K+', genre: 'Political', director: 'Shekhar Kammula', image: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?q=80&w=400' }
            ];
            state.movies = !query ? fallback : fallback.filter(m => m.title.toLowerCase().includes(query.toLowerCase()));
            renderContent();
        }

        let unsubscribeSeats = null;

        async function navigate(step, data = {}) {
            if ((step === 'checkout' || step === 'profile') && !state.isAuthenticated) {
                state.step = 'login';
                state.authMode = 'signin';
                state.authMessage = { text: 'Sign in to book.', type: 'error' };
                render();
                return;
            }

            // RESET LOGIC: Clear seats when starting a new selection flow
            if (['home', 'detail', 'theatre'].includes(step)) {
                state.selectedSeats = [];
            }

            if (unsubscribeSeats) { unsubscribeSeats(); unsubscribeSeats = null; }
            state.step = step;
            if (step !== 'login') state.authMessage = null;
            Object.assign(state, data);

            if (step === 'theatre') await fetchTheatersFromServlet(state.selectedLocation);

            if (step === 'seats' && window.db) {
                const showId = `${state.selectedMovie.id}_${state.selectedTheater.id}_${state.selectedDate.id}_${state.selectedTime.replace(/ /g, '_')}`;
                const showRef = window.fs.doc(window.db, 'artifacts', window.appId, 'public', 'data', 'shows', showId);
                unsubscribeSeats = window.fs.onSnapshot(showRef, (docSnap) => {
                    state.globalBookedSeats = docSnap.exists() ? (docSnap.data().bookedSeats || []) : [];
                    renderContent();
                });
            }
            window.scrollTo({ top: 0, behavior: 'smooth' });
            render(); 
        }

        async function handleAuth(e) {
            e.preventDefault();
            const email = document.getElementById('auth-email').value;
            const password = document.getElementById('auth-password').value;
            const name = document.getElementById('auth-name')?.value;
            try {
                if (state.authMode === 'signup') {
                    const res = await window.fs.createUserWithEmailAndPassword(window.auth, email, password);
                    await window.fs.setDoc(window.fs.doc(window.db, 'artifacts', window.appId, 'users', res.user.uid, 'profile', 'data'), { name, email, phone: '+91 79813 38737' });
                    state.authMessage = { text: 'Account Created!', type: 'success' };
                    state.authMode = 'signin';
                } else {
                    await window.fs.signInWithEmailAndPassword(window.auth, email, password);
                }
            } catch (err) { state.authMessage = { text: err.message, type: 'error' }; }
            render();
        }

        async function handleGoogleAuth() {
            try {
                await window.fs.signInWithPopup(window.auth, window.googleProvider);
            } catch (err) {
                state.authMessage = { text: err.message, type: 'error' };
                render();
            }
        }

        async function handleForgotPassword() {
            const email = document.getElementById('auth-email')?.value;
            if (!email) { state.authMessage = { text: 'Enter email.', type: 'error' }; render(); return; }
            try {
                await window.fs.sendPasswordResetEmail(window.auth, email);
                state.authMessage = { text: 'Link sent to ' + email, type: 'success' };
            } catch (err) { state.authMessage = { text: err.message, type: 'error' }; }
            render();
        }

        async function logout() {
            try { await window.fs.signOut(window.auth); } catch (e) {}
            state.isAuthenticated = false;
            state.userProfile = null;
            state.selectedSeats = [];
            navigate('home');
        }

        function toggleLocationModal(show) {
            const modal = document.getElementById('locationModal');
            modal.style.display = show ? 'flex' : 'none';
            if(show) renderLocations();
        }

        function renderLocations() {
            const container = document.getElementById('locationList');
            container.innerHTML = LOCATIONS.map(loc => `<div onclick="setLocation('${loc}')" class="px-6 py-4 flex justify-between items-center border-b hover:bg-gray-50 cursor-pointer transition-all"><span class="text-sm ${state.selectedLocation === loc ? 'text-rose-500 font-bold' : 'text-gray-700'}">${loc}</span>${state.selectedLocation === loc ? '<i class="fa-solid fa-check text-rose-500"></i>' : ''}</div>`).join('');
        }

        async function setLocation(loc) { 
            state.selectedLocation = loc; 
            toggleLocationModal(false); 
            if(state.step === 'theatre') await navigate('theatre');
            else render(); 
        }

        // TICKET POPUP LOGIC
        function showTicketPopup(bookingId) {
            const b = state.bookingHistory.find(item => item.id === bookingId);
            if (!b) return;

            const modal = document.getElementById('ticketModal');
            const container = document.getElementById('ticketDataContainer');
            
            container.innerHTML = `
                <div class="bg-white rounded-[40px] shadow-2xl overflow-hidden animate-in zoom-in duration-300">
                    <div class="bg-rose-500 p-8 text-white text-center">
                        <h3 class="font-black text-2xl uppercase tracking-tighter leading-tight">${b.movie}</h3>
                        <p class="text-[10px] font-bold uppercase opacity-80 mt-1">Confirmed Digital Ticket</p>
                    </div>
                    <div class="p-8 space-y-6">
                        <div class="grid grid-cols-2 gap-4">
                            <div>
                                <p class="text-[10px] font-black text-gray-300 uppercase">Theatre</p>
                                <p class="text-sm font-black text-gray-800">${b.theater}</p>
                            </div>
                            <div class="text-right">
                                <p class="text-[10px] font-black text-gray-300 uppercase">Showtime</p>
                                <p class="text-sm font-black text-gray-800">${b.time}</p>
                            </div>
                            <div>
                                <p class="text-[10px] font-black text-gray-300 uppercase">Date</p>
                                <p class="text-sm font-black text-gray-800">${b.date}</p>
                            </div>
                            <div class="text-right">
                                <p class="text-[10px] font-black text-gray-300 uppercase">Seats</p>
                                <p class="text-sm font-black text-rose-500 font-black">${b.seats}</p>
                            </div>
                        </div>

                        <div class="flex items-center gap-4 py-6 border-y border-dashed border-gray-100 ticket-cut">
                            <div class="flex-grow">
                                <p class="text-[10px] font-black text-gray-300 uppercase">Booking ID</p>
                                <p class="text-lg font-black tracking-widest text-gray-900 leading-none">${b.id}</p>
                            </div>
                            <img src="https://api.qrserver.com/v1/create-qr-code/?size=100x100&data=CB_BOOK_${b.id}" class="w-20 h-20 rounded-xl">
                        </div>

                        <div class="text-center space-y-4">
                            <p class="text-xs font-bold text-gray-500 italic">"Thank you for choosing CineBooking! Your cinematic journey awaits. Please present this QR at the entrance."</p>
                            <div class="bg-gray-50 p-4 rounded-3xl">
                                <p class="text-[9px] font-black text-gray-400 uppercase">Total Paid</p>
                                <p class="text-xl font-black text-gray-900">${b.price}</p>
                            </div>
                        </div>
                    </div>
                </div>
            `;
            modal.style.display = 'flex';
        }

        function closeTicketModal() {
            document.getElementById('ticketModal').style.display = 'none';
        }

        function render() {
            const nav = document.getElementById('navbar-container');
            const mobileNav = document.getElementById('mobile-nav-container');
            if (nav) nav.innerHTML = renderNavbar();
            if (mobileNav) mobileNav.innerHTML = renderMobileNav();
            renderContent();
        }

        function renderContent() {
            const content = document.getElementById('content-container');
            if (content) content.innerHTML = renderStepContent();
        }

        function renderNavbar() {
            if(['ticket', 'seats', 'login'].includes(state.step)) return '';
            return `<nav class="bg-white border-b sticky top-0 z-40 shadow-sm"><div class="max-w-7xl mx-auto px-4 lg:px-8 flex items-center justify-between h-16 lg:h-20"><div class="flex items-center gap-8"><div onclick="navigate('home')" class="cursor-pointer"><h1 class="text-2xl lg:text-3xl font-black text-rose-500 tracking-tighter">CineBooking</h1></div><div class="hidden md:flex items-center bg-gray-100 rounded-lg px-4 py-2 w-96 border border-gray-200 focus-within:border-rose-300"><i class="fa-solid fa-magnifying-glass text-gray-400"></i><input type="text" oninput="fetchMovies(this.value)" placeholder="Search Movie" class="bg-transparent border-none outline-none ml-3 text-sm w-full" value="${state.searchQuery}"></div></div><div class="flex items-center gap-6"><div class="hidden lg:flex items-center gap-1 cursor-pointer" onclick="toggleLocationModal(true)"><span class="text-sm font-bold text-gray-700">${state.selectedLocation}</span><i class="fa-solid fa-chevron-down text-[10px] ml-1"></i></div>${state.isAuthenticated ? `<div onclick="navigate('profile')" class="flex items-center gap-3 cursor-pointer group"><span class="hidden lg:block text-sm font-bold text-gray-600 group-hover:text-rose-500">${state.userProfile.name.split(' ')[0]}</span><div class="w-10 h-10 bg-rose-100 rounded-full flex items-center justify-center text-rose-500 font-bold border-2 border-white shadow-sm">${state.userProfile.name.charAt(0)}</div></div>` : `<button onclick="navigate('login')" class="bg-rose-500 text-white px-6 py-2 rounded-xl text-sm font-bold shadow-lg hover:bg-rose-600 transition-all">Sign In</button>`}</div></div></nav>`;
        }

        function renderStepContent() {
            switch(state.step) {
                case 'home': return renderHomeView();
                case 'movies': return renderMoviesView();
                case 'detail': return renderDetail();
                case 'theatre': return renderTheatre();
                case 'seats': return renderSeatsView();
                case 'checkout': return renderCheckoutView();
                case 'ticket': return renderTicketView();
                case 'profile': return renderProfile();
                case 'login': return renderLoginView();
                default: return renderHomeView();
            }
        }

        function renderLoginView() {
            const isSignIn = state.authMode === 'signin';
            return `<div class="min-h-[80vh] flex items-center justify-center p-4">
                <div class="auth-card relative w-full max-w-md bg-white p-8 md:p-12 rounded-[40px] shadow-2xl border border-gray-100">
                    <i onclick="navigate('home')" class="fa-solid fa-arrow-left absolute top-10 left-10 text-gray-300 cursor-pointer hover:text-rose-500 text-lg"></i>
                    <div class="text-center mb-10">
                        <h2 class="text-3xl font-black text-rose-500 mb-2">CineBooking</h2>
                        <p class="text-gray-400 font-bold text-sm">${isSignIn ? 'Welcome back!' : 'Join us today'}</p>
                    </div>
                    ${state.authMessage ? `<div class="mb-6 p-4 rounded-2xl text-xs font-bold text-center ${state.authMessage.type === 'success' ? 'bg-emerald-50 text-emerald-600' : 'bg-rose-50 text-rose-600'}">${state.authMessage.text}</div>` : ''}
                    <form onsubmit="handleAuth(event)" class="space-y-4">
                        ${!isSignIn ? `<div><label class="text-[10px] font-black text-gray-400 uppercase ml-2">Full Name</label><input type="text" id="auth-name" required class="w-full mt-1 p-4 bg-gray-50 border border-transparent rounded-2xl outline-none focus:bg-white focus:border-rose-500 font-bold transition-all" placeholder="Enter name"></div>` : ''}
                        <div><label class="text-[10px] font-black text-gray-400 uppercase ml-2">Email Address</label><input type="email" id="auth-email" required class="w-full mt-1 p-4 bg-gray-50 border border-transparent rounded-2xl outline-none focus:bg-white focus:border-rose-500 font-bold transition-all" placeholder="name@example.com"></div>
                        <div class="relative">
                            <label class="text-[10px] font-black text-gray-400 uppercase ml-2">Password</label>
                            <input type="password" id="auth-password" required class="w-full mt-1 p-4 bg-gray-50 border border-transparent rounded-2xl outline-none focus:bg-white focus:border-rose-500 font-bold transition-all" placeholder="••••••••">
                            ${isSignIn ? `<button type="button" onclick="handleForgotPassword()" class="absolute right-4 bottom-4 text-[10px] font-black text-rose-500 hover:underline">Forgot?</button>` : ''}
                        </div>
                        <button type="submit" class="w-full bg-rose-500 text-white py-5 rounded-2xl font-black text-lg shadow-xl mt-4">${isSignIn ? 'Sign In' : 'Create Account'}</button>
                    </form>
                    <div class="mt-8 flex items-center gap-4"><div class="flex-grow h-px bg-gray-100"></div><span class="text-[10px] font-black text-gray-300 uppercase">Or</span><div class="flex-grow h-px bg-gray-100"></div></div>
                    <button onclick="handleGoogleAuth()" class="w-full mt-6 border-2 border-gray-100 py-4 rounded-2xl font-black text-sm flex items-center justify-center gap-3 hover:bg-gray-50 transition-all"><img src="https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg" class="w-5"> Sign in with Google</button>
                    <p class="text-center mt-10 text-sm font-bold text-gray-500">${isSignIn ? "New here?" : "Joined?"} <span onclick="state.authMode = '${isSignIn ? 'signup' : 'signin'}'; state.authMessage = null; render()" class="text-rose-500 cursor-pointer hover:underline">${isSignIn ? 'Sign Up' : 'Sign In'}</span></p>
                </div>
            </div>`;
        }

        function renderProfile() {
            const p = state.userProfile;
            if (!p) return `<div class="text-center py-20 text-gray-400 font-bold italic">User not logged in.</div>`;
            return `
                <div class="max-w-4xl mx-auto space-y-8 animate-in slide-in-from-bottom duration-500 pb-20">
                    <div class="bg-white p-8 md:p-12 rounded-[40px] shadow-xl border border-gray-50 flex flex-col md:flex-row items-center gap-8">
                        <div class="w-32 h-32 bg-rose-50 rounded-full flex items-center justify-center text-rose-500 text-4xl font-black">${p.name.charAt(0)}</div>
                        <div class="text-center md:text-left flex-grow">
                            <h2 class="text-3xl font-black">${p.name}</h2>
                            <p class="text-gray-400 font-bold text-sm uppercase tracking-widest">CinePass Member</p>
                            <div class="mt-4 flex gap-3 flex-wrap justify-center md:justify-start">
                                <span class="bg-gray-100 text-gray-500 px-4 py-1.5 rounded-full text-[10px] font-black uppercase"><i class="fa-solid fa-envelope mr-1"></i> ${p.email}</span>
                            </div>
                        </div>
                        <div class="flex flex-col gap-2 w-full md:w-auto"><button onclick="logout()" class="border-2 border-gray-100 text-gray-400 px-8 py-3 rounded-2xl font-black text-sm hover:border-rose-500 hover:text-rose-500 transition-all"><i class="fa-solid fa-right-from-bracket mr-2"></i>Logout</button></div>
                    </div>
                    <div class="bg-white p-8 md:p-10 rounded-[40px] border border-gray-50 shadow-xl">
                        <h3 class="text-xl font-black mb-8 flex items-center gap-3"><i class="fa-solid fa-clock-rotate-left text-rose-500"></i>Booking History</h3>
                        <div class="space-y-4">
                            ${state.bookingHistory.length > 0 ? state.bookingHistory.map(b => `
                                <div onclick="showTicketPopup('${b.id}')" class="flex items-center justify-between p-6 bg-gray-50 rounded-[30px] border border-transparent hover:border-rose-100 cursor-pointer transition-all">
                                    <div>
                                        <p class="font-black text-gray-900">${b.movie}</p>
                                        <p class="text-[10px] font-bold text-gray-400 uppercase mt-1">${b.date} • ${b.seats}</p>
                                    </div>
                                    <div class="text-right">
                                        <p class="font-black text-gray-900">${b.price}</p>
                                        <p class="text-[9px] font-black text-emerald-500 uppercase tracking-widest">${b.status}</p>
                                    </div>
                                </div>
                            `).join('') : '<p class="text-center text-gray-400 py-4">No recent bookings found.</p>'}
                        </div>
                    </div>
                </div>
            `;
        }

        function renderHomeView() {
            return `${!state.searchQuery ? `<div class="mb-10 rounded-2xl overflow-hidden shadow-xl shadow-blue-100 group cursor-pointer"><div class="bg-gradient-to-r from-blue-700 to-blue-500 p-8 lg:p-12 text-white flex justify-between items-center relative overflow-hidden"><div class="z-10"><h2 class="text-4xl lg:text-6xl font-black italic mb-2">5% <span class="text-xl not-italic">Unlimited</span></h2><p class="text-sm font-bold uppercase tracking-widest opacity-80">Cashback with CineCard</p><button class="mt-4 bg-white text-blue-700 px-6 py-2 rounded-full font-black text-xs uppercase">Apply Now</button></div><div class="z-10 bg-white/10 p-4 rounded-3xl backdrop-blur-md border border-white/20 rotate-12 transition-transform"><div class="w-16 h-24 bg-black rounded-lg flex items-center justify-center text-3xl font-bold">P</div></div></div></div>` : ''}<div class="flex justify-between items-center mb-8"><h3 class="text-xl font-black text-gray-800">${state.searchQuery ? 'Search Results' : 'Recommended'}</h3>${!state.searchQuery ? `<span onclick="navigate('movies')" class="text-rose-500 text-sm font-bold cursor-pointer hover:underline">See All</span>` : ''}</div>${renderMoviesGrid()}`;
        }

        function renderMoviesView() {
            return `<div class="flex items-center gap-4 mb-8"><i onclick="navigate('home')" class="fa-solid fa-arrow-left text-gray-400 cursor-pointer"></i><h2 class="text-3xl font-black">All Movies</h2></div>${renderMoviesGrid()}`;
        }

        function renderMoviesGrid() {
            if (state.movies.length === 0) return `<div class="py-20 text-center text-gray-400 font-bold">No movies found.</div>`;
            return `<div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-8">${state.movies.map(m => `
                <div onclick='navigate("detail", {selectedMovie: ${JSON.stringify(m)}})' class="cursor-pointer group">
                    <div class="relative aspect-[2/3] rounded-2xl overflow-hidden shadow-lg transition-transform group-hover:-translate-y-2">
                        <img src="${m.image}" class="w-full h-full object-cover">
                        <div class="absolute bottom-0 left-0 right-0 bg-black/60 p-4 text-white text-xs font-bold flex justify-between backdrop-blur-sm">
                            <span>⭐ ${m.rating}</span><span class="opacity-60">8.1K+</span>
                        </div>
                    </div>
                    <h4 class="mt-4 font-black text-base leading-tight">${m.title}</h4>
                    <p class="text-[10px] text-gray-400 font-bold uppercase mt-1 tracking-widest">${m.genre}</p>
                </div>`).join('')}</div>`;
        }

        function renderDetail() {
            const m = state.selectedMovie;
            return `<div class="flex items-center gap-4 mb-8"><i onclick="navigate('home')" class="fa-solid fa-chevron-left text-gray-400 cursor-pointer"></i><h2 class="text-xl font-black">${m.title}</h2></div><div class="grid grid-cols-1 lg:grid-cols-3 gap-12"><img src="${m.image}" class="rounded-3xl shadow-2xl aspect-[2/3] object-cover w-full shadow-rose-200/50"><div class="lg:col-span-2 pt-4"><div class="flex items-center gap-4"><span class="text-3xl font-black">⭐ ${m.rating}/10</span><span class="bg-gray-100 px-3 py-1 rounded text-[10px] font-black uppercase text-gray-500">2D, 3D</span></div><p class="mt-4 text-gray-600 leading-relaxed">Experience ${m.title} in the best screens of ${state.selectedLocation}. Join the adventure with top-rated visuals and surround sound.</p><button onclick="navigate('theatre')" class="mt-10 bg-rose-500 text-white px-16 py-5 rounded-2xl font-black text-xl shadow-xl hover:-translate-y-1 transition-all">Book tickets</button></div></div>`;
        }

        function renderTheatre() {
            if(!state.selectedDate) state.selectedDate = availableDates[0];
            return `<div class="flex items-center gap-4 mb-8 border-b pb-4"><i onclick="navigate('detail')" class="fa-solid fa-chevron-left text-gray-400 cursor-pointer"></i><h2 class="font-black">${state.selectedMovie.title}</h2></div><div class="mb-10 flex gap-4 overflow-x-auto no-scrollbar pb-4">${availableDates.map(d => `<div onclick='state.selectedDate = ${JSON.stringify(d)}; render()' class="min-w-[75px] p-4 rounded-2xl cursor-pointer text-center ${state.selectedDate.id === d.id ? 'bg-rose-500 text-white shadow-lg' : 'bg-white border text-gray-400'}"><p class="text-[9px] font-black uppercase">${d.day}</p><p class="text-lg font-black">${d.dateNum}</p></div>`).join('')}</div><div class="space-y-6">${currentTheaters.map(t => { const filteredTimes = t.times.filter(time => !isTimePast(time, state.selectedDate.id)); if (filteredTimes.length === 0) return ''; return `<div class="p-8 bg-white rounded-3xl border border-gray-100 shadow-sm animate-in fade-in duration-300"><h3 class="font-black text-lg text-gray-800">${t.name}</h3><div class="flex flex-wrap gap-4 mt-6">${filteredTimes.map(time => `<button onclick='navigate("seats", {selectedTheater: ${JSON.stringify(t)}, selectedTime: "${time}"})' class="border-2 border-emerald-500/20 px-6 py-3 rounded-xl font-black text-emerald-600 hover:bg-emerald-50 transition-all">${time}</button>`).join('')}</div></div>`; }).join('')}</div>`;
        }

        async function renderSeatsView() {
            const rows = ['A', 'B', 'C', 'D', 'E', 'F'];
            // Amount reset to zero: fee is NOT applied here
            const cost = await getCostFromServlet(state.selectedSeats.length, false);
            const container = document.getElementById('content-container');
            container.innerHTML = `<div class="max-w-4xl mx-auto flex flex-col items-center bg-white p-12 rounded-[40px] shadow-2xl border border-gray-100 auth-card"><header class="w-full flex justify-between items-center mb-12 border-b pb-6"><i onclick="navigate('theatre')" class="fa-solid fa-chevron-left text-gray-300 cursor-pointer"></i><div class="text-center"><p class="font-black text-sm">${state.selectedMovie.title}</p><p class="text-[10px] font-bold text-gray-400 uppercase tracking-widest">${state.selectedTheater.name} | ${state.selectedTime}</p></div><div class="w-4"></div></header><div class="inline-block relative"><div class="mb-12 w-full text-center text-[9px] font-black text-gray-200 uppercase tracking-[1em]">All eyes this way</div>${rows.map(row => `<div class="flex gap-4 mb-4 items-center"><span class="w-8 text-[10px] font-black text-gray-200">${row}</span><div class="flex gap-2">${Array.from({length: 12}, (_, i) => { const id = row + (i+1); const isOcc = state.globalBookedSeats.includes(id); const isSel = state.selectedSeats.includes(id); if (isOcc) return `<div class="w-8 h-8 rounded-lg flex items-center justify-center text-[10px] font-black bg-gray-100 text-gray-300 border-2 border-gray-200 cursor-not-allowed">${i+1}</div>`; return `<div onclick="toggleSeat('${id}')" class="w-8 h-8 rounded-lg cursor-pointer flex items-center justify-center text-[10px] font-black border-2 ${isSel ? 'bg-rose-500 border-rose-500 text-white scale-110 shadow-lg' : 'border-emerald-400 text-emerald-500 bg-emerald-50/20 hover:bg-emerald-50'}">${i+1}</div>`; }).join('')}</div></div>`).join('')}</div><button onclick="navigate('checkout')" ${state.selectedSeats.length === 0 ? 'disabled' : ''} class="mt-12 bg-rose-500 text-white px-12 py-4 rounded-2xl font-black text-lg disabled:opacity-20 shadow-xl transition-all">Pay ₹${cost.total.toFixed(2)}</button></div>`;
        }

        function toggleSeat(id) {
            if(state.selectedSeats.includes(id)) state.selectedSeats = state.selectedSeats.filter(s => s !== id);
            else state.selectedSeats.push(id);
            renderContent();
        }

        async function renderCheckoutView() {
            // Fee IS applied during checkout (includeFee = true)
            const cost = await getCostFromServlet(state.selectedSeats.length, true);
            const container = document.getElementById('content-container');
            const subtotal = state.selectedSeats.length * 250;
            container.innerHTML = `<div class="max-w-2xl mx-auto bg-white p-10 rounded-[40px] shadow-2xl border border-gray-100 auth-card"><h2 class="text-3xl font-black mb-8">Confirm Booking</h2><div class="space-y-4 mb-10"><div class="flex justify-between font-bold text-gray-500"><span>Movie</span><span class="text-gray-900">${state.selectedMovie.title}</span></div><div class="flex justify-between font-bold text-gray-500"><span>Seats</span><span class="text-gray-900">${state.selectedSeats.join(', ')}</span></div><div class="flex justify-between font-bold text-gray-500"><span>Base Fare</span><span class="text-gray-900">₹${subtotal.toFixed(2)}</span></div><div class="flex justify-between font-bold text-gray-500"><span>GST (18%)</span><span class="text-gray-900">₹${cost.gst.toFixed(2)}</span></div><div class="flex justify-between font-bold text-gray-500"><span>Conv. Fee (2%)</span><span class="text-gray-900 text-rose-500 font-black">+ ₹${cost.fee.toFixed(2)}</span></div><div class="flex justify-between text-2xl font-black text-rose-500 border-t pt-4"><span>Total Amount</span><span>₹${cost.total.toFixed(2)}</span></div></div><div class="flex flex-col gap-4"><button onclick="processBooking()" class="w-full bg-rose-500 text-white py-5 rounded-2xl font-black text-xl shadow-xl hover:bg-rose-600 transition-all">Proceed to Payment</button><button onclick="navigate('seats')" class="w-full border-2 border-gray-100 text-gray-400 py-4 rounded-2xl font-black hover:bg-gray-50 transition-all">Go Back</button></div></div>`;
        }

        async function processBooking() {
            state.bookingId = Math.random().toString(36).substring(7).toUpperCase();
            const showId = `${state.selectedMovie.id}_${state.selectedTheater.id}_${state.selectedDate.id}_${state.selectedTime.replace(/ /g, '_')}`;
            const showRef = window.fs.doc(window.db, 'artifacts', window.appId, 'public', 'data', 'shows', showId);
            const currentSnap = await window.fs.getDoc(showRef);
            const alreadyBooked = currentSnap.exists() ? (currentSnap.data().bookedSeats || []) : [];
            if (state.selectedSeats.some(s => alreadyBooked.includes(s))) { state.authMessage = { text: 'One or more seats were just booked. Please re-select.', type: 'error' }; navigate('seats'); return; }
            await window.fs.setDoc(showRef, { bookedSeats: window.fs.arrayUnion(...state.selectedSeats) }, { merge: true });
            
            const cost = await getCostFromServlet(state.selectedSeats.length, true);
            const newBooking = { 
                id: state.bookingId, 
                movie: state.selectedMovie.title, 
                date: state.selectedDate.full, 
                time: state.selectedTime, 
                theater: state.selectedTheater.name, 
                seats: state.selectedSeats.join(', '), 
                status: 'Confirmed', 
                price: `₹${cost.total.toFixed(2)}` 
            };
            state.bookingHistory.unshift(newBooking);
            await window.fs.setDoc(window.fs.doc(window.db, 'artifacts', window.appId, 'users', window.auth.currentUser.uid, 'history', 'list'), { bookings: state.bookingHistory });
            
            // Amount reset to zero: clear state for next booking
            state.selectedSeats = [];
            navigate('ticket');
        }

        async function renderTicketView() {
            const container = document.getElementById('content-container');
            container.innerHTML = `<div class="text-center py-20 animate-in fade-in duration-700"><div class="inline-flex items-center justify-center w-20 h-20 bg-emerald-100 text-emerald-600 rounded-full mb-6"><i class="fa-solid fa-check text-4xl"></i></div><h2 class="text-3xl font-black mb-2 text-gray-900">Booking Success!</h2><p class="text-gray-400 font-bold mb-10">Your digital ticket has been generated and saved to your history.</p><button onclick="navigate('home')" class="bg-gray-900 text-white px-10 py-4 rounded-2xl font-black uppercase text-xs tracking-widest hover:bg-black transition-all">Return Home</button></div>`;
            
            const user = window.auth.currentUser;
            if (user) {
                 const historyRef = window.fs.doc(window.db, 'artifacts', window.appId, 'users', user.uid, 'history', 'list');
                 const historySnap = await window.fs.getDoc(historyRef);
                 if (historySnap.exists()) state.bookingHistory = historySnap.data().bookings || [];
            }
        }

        function renderMobileNav() {
            if(['login', 'seats', 'ticket'].includes(state.step)) return '';
            const step = state.step;
            return `<nav class="lg:hidden fixed bottom-0 w-full bg-white border-t flex justify-around py-4 z-50 shadow-lg"><div onclick="navigate('home')" class="nav-item ${step === 'home' ? 'nav-active' : 'nav-inactive'}"><i class="fa-solid fa-house"></i><span>Home</span></div><div onclick="navigate('movies')" class="nav-item ${['movies', 'detail', 'theatre'].includes(step) ? 'nav-active' : 'nav-inactive'}"><i class="fa-solid fa-clapperboard"></i><span>Movies</span></div><div onclick="navigate('profile')" class="nav-item ${step === 'profile' ? 'nav-active' : 'nav-inactive'}"><i class="fa-solid fa-user"></i><span>Profile</span></div></nav>`;
        }

        render();
        fetchMovies();
    </script>
</body>
</html>