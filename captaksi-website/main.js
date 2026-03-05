// ─── NAVBAR SCROLL ───────────────────────────────────────
const navbar = document.getElementById('navbar');
window.addEventListener('scroll', () => {
    navbar.classList.toggle('scrolled', window.scrollY > 40);
});

// ─── HAMBURGER MENU ──────────────────────────────────────
const hamburger = document.getElementById('hamburger');
const navLinks = document.querySelector('.nav-links');
hamburger.addEventListener('click', () => {
    navLinks.classList.toggle('open');
    hamburger.classList.toggle('active');
});
navLinks.querySelectorAll('a').forEach(a => {
    a.addEventListener('click', () => {
        navLinks.classList.remove('open');
        hamburger.classList.remove('active');
    });
});

// ─── SCROLL REVEAL ───────────────────────────────────────
const observer = new IntersectionObserver((entries) => {
    entries.forEach(e => {
        if (e.isIntersecting) {
            const delay = e.target.dataset.delay || 0;
            setTimeout(() => e.target.classList.add('visible'), parseInt(delay));
        }
    });
}, { threshold: 0.12 });

document.querySelectorAll('.feature-card, .step, .d-stat, .contact-item').forEach(el => {
    el.classList.add('scroll-reveal');
    observer.observe(el);
});

// ─── SMOOTH ACTIVE NAV ───────────────────────────────────
const sections = document.querySelectorAll('section[id]');
window.addEventListener('scroll', () => {
    let current = '';
    sections.forEach(s => {
        if (window.scrollY >= s.offsetTop - 120) current = s.getAttribute('id');
    });
    document.querySelectorAll('.nav-links a').forEach(a => {
        a.classList.remove('active');
        if (a.getAttribute('href') === `#${current}`) a.classList.add('active');
    });
});

// ─── CONTACT FORM ─────────────────────────────────────────
const form = document.getElementById('contactForm');
const submitBtn = document.getElementById('submitBtn');
const submitText = document.getElementById('submitText');
const submitLoader = document.getElementById('submitLoader');
const feedback = document.getElementById('formFeedback');

if (form) {
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        // Loading state
        submitText.style.display = 'none';
        submitLoader.style.display = 'inline';
        submitBtn.disabled = true;
        feedback.className = 'form-feedback';
        feedback.style.display = 'none';

        try {
            const formData = new FormData(form);
            const response = await fetch('send_mail.php', {
                method: 'POST',
                body: formData,
            });
            const result = await response.json();

            feedback.className = result.success
                ? 'form-feedback success'
                : 'form-feedback error';
            feedback.textContent = result.message;

            if (result.success) form.reset();
        } catch {
            feedback.className = 'form-feedback error';
            feedback.textContent = 'Bir hata oluştu. Lütfen tekrar deneyin.';
        } finally {
            submitText.style.display = 'inline';
            submitLoader.style.display = 'none';
            submitBtn.disabled = false;
        }
    });
}

// ─── STATS COUNTER ANIMATION ─────────────────────────────
function animateCounter(el, target, suffix = '') {
    let start = 0;
    const duration = 2000;
    const step = target / (duration / 16);
    const timer = setInterval(() => {
        start += step;
        if (start >= target) { start = target; clearInterval(timer); }
        const display = target >= 1000
            ? (start / 1000).toFixed(1) + 'K'
            : Math.floor(start).toString();
        el.textContent = display + suffix;
    }, 16);
}

const statsObserver = new IntersectionObserver((entries) => {
    entries.forEach(e => {
        if (!e.isIntersecting) return;
        const el = e.target;
        const raw = el.dataset.count;
        if (!raw) return;
        animateCounter(el, parseFloat(raw), el.dataset.suffix || '');
        statsObserver.unobserve(el);
    });
}, { threshold: 0.5 });

document.querySelectorAll('[data-count]').forEach(el => statsObserver.observe(el));
