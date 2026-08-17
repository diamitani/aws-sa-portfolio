// ============================================================
// PATRICK DIAMITANI — AWS PORTFOLIO
// main.js — Animations, interactions, scroll effects
// ============================================================

(function () {
  'use strict';

  // ── Nav scroll effect ──────────────────────────────────────
  const nav = document.querySelector('.nav');
  if (nav) {
    window.addEventListener('scroll', () => {
      nav.classList.toggle('scrolled', window.scrollY > 40);
    }, { passive: true });
  }

  // ── Scroll Reveal ──────────────────────────────────────────
  const reveals = document.querySelectorAll('.reveal');
  if (reveals.length) {
    const revealObs = new IntersectionObserver((entries) => {
      entries.forEach(e => {
        if (e.isIntersecting) {
          e.target.classList.add('visible');
          revealObs.unobserve(e.target);
        }
      });
    }, { threshold: 0.1, rootMargin: '0px 0px -60px 0px' });
    reveals.forEach(el => revealObs.observe(el));
  }

  // ── Typing effect ──────────────────────────────────────────
  const typingEl = document.getElementById('typing-target');
  if (typingEl) {
    const phrases = [
      'agentic AI pipelines',
      'multi-tenant SaaS',
      'startup GTM engines',
      'AWS cloud architecture',
      'revenue automation',
    ];
    let phraseIdx = 0;
    let charIdx = 0;
    let deleting = false;
    let paused = false;

    function type() {
      if (paused) return;
      const current = phrases[phraseIdx];

      if (!deleting) {
        typingEl.textContent = current.slice(0, charIdx + 1);
        charIdx++;
        if (charIdx === current.length) {
          deleting = true;
          paused = true;
          setTimeout(() => { paused = false; }, 2200);
        }
      } else {
        typingEl.textContent = current.slice(0, charIdx - 1);
        charIdx--;
        if (charIdx === 0) {
          deleting = false;
          phraseIdx = (phraseIdx + 1) % phrases.length;
        }
      }
    }

    setInterval(type, deleting ? 55 : 90);
    setInterval(type, 90);
  }

  // ── Floating particles ────────────────────────────────────
  const particleContainer = document.querySelector('.particles');
  if (particleContainer) {
    const COUNT = 18;
    for (let i = 0; i < COUNT; i++) {
      const p = document.createElement('div');
      p.className = 'particle';
      const left = Math.random() * 100;
      const dur  = 12 + Math.random() * 20;
      const del  = Math.random() * 15;
      const size = Math.random() > 0.7 ? 3 : 2;
      p.style.cssText = `left:${left}%;width:${size}px;height:${size}px;animation-duration:${dur}s;animation-delay:-${del}s;opacity:0`;
      if (Math.random() > 0.6) p.style.background = 'rgba(255,153,0,0.6)';
      particleContainer.appendChild(p);
    }
  }

  // ── Counter animation ─────────────────────────────────────
  function animateCounter(el, target, duration = 1800, prefix = '', suffix = '') {
    const start = performance.now();
    const isFloat = String(target).includes('.');
    const decimals = isFloat ? 1 : 0;

    function update(now) {
      const elapsed = now - start;
      const progress = Math.min(elapsed / duration, 1);
      // Ease out expo
      const eased = progress === 1 ? 1 : 1 - Math.pow(2, -10 * progress);
      const value = eased * target;
      el.textContent = prefix + value.toFixed(decimals) + suffix;
      if (progress < 1) requestAnimationFrame(update);
    }

    requestAnimationFrame(update);
  }

  const statEls = document.querySelectorAll('[data-count]');
  if (statEls.length) {
    const countObs = new IntersectionObserver((entries) => {
      entries.forEach(e => {
        if (e.isIntersecting) {
          const el = e.target;
          const target = parseFloat(el.dataset.count);
          const prefix = el.dataset.prefix || '';
          const suffix = el.dataset.suffix || '';
          animateCounter(el, target, 1800, prefix, suffix);
          countObs.unobserve(el);
        }
      });
    }, { threshold: 0.5 });
    statEls.forEach(el => countObs.observe(el));
  }

  // ── Smooth scroll for anchor links ────────────────────────
  document.querySelectorAll('a[href^="#"]').forEach(a => {
    a.addEventListener('click', e => {
      const target = document.querySelector(a.getAttribute('href'));
      if (target) {
        e.preventDefault();
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    });
  });

  // ── Active nav link tracking ──────────────────────────────
  const sections = document.querySelectorAll('section[id]');
  const navLinks = document.querySelectorAll('.nav-link[href^="#"]');

  if (sections.length && navLinks.length) {
    const sectionObs = new IntersectionObserver((entries) => {
      entries.forEach(e => {
        if (e.isIntersecting) {
          navLinks.forEach(link => {
            link.style.color = link.getAttribute('href') === '#' + e.target.id
              ? 'var(--text-primary)' : '';
          });
        }
      });
    }, { threshold: 0.4 });
    sections.forEach(s => sectionObs.observe(s));
  }

  // ── Arch node staggered entrance ─────────────────────────
  const archNodes = document.querySelectorAll('.arch-node');
  archNodes.forEach((node, i) => {
    node.style.opacity = '0';
    node.style.transform = 'translateX(-16px)';
    node.style.transition = `opacity 0.5s ${0.3 + i * 0.1}s, transform 0.5s ${0.3 + i * 0.1}s`;
    setTimeout(() => {
      node.style.opacity = '1';
      node.style.transform = 'translateX(0)';
    }, 100);
  });

  // ── Pillar card color on hover ────────────────────────────
  const pillarColors = ['#FF6B35', '#FF9900', '#4A9EFF', '#00D4AA', '#8B5CF6', '#EC4899'];
  document.querySelectorAll('.pillar-card').forEach((card, i) => {
    const color = pillarColors[i % pillarColors.length];
    card.addEventListener('mouseenter', () => {
      card.style.setProperty('--pillar-color', color);
      card.querySelector('.pillar-icon')?.style?.setProperty('filter', `drop-shadow(0 0 8px ${color})`);
    });
    card.addEventListener('mouseleave', () => {
      if (card.querySelector('.pillar-icon')) {
        card.querySelector('.pillar-icon').style.filter = '';
      }
    });
  });

  // ── Mobile nav toggle ─────────────────────────────────────
  const mobileToggle = document.querySelector('.nav-mobile-toggle');
  const mobileMenu = document.querySelector('.nav-mobile-menu');
  if (mobileToggle && mobileMenu) {
    mobileToggle.addEventListener('click', () => {
      const open = mobileMenu.classList.toggle('open');
      mobileToggle.setAttribute('aria-expanded', open);
    });
  }

  // ── Console easter egg ────────────────────────────────────
  console.log('%c Patrick Diamitani — AWS Solutions Architect ', 'background:#FF6B35;color:#fff;font-size:14px;font-weight:bold;padding:8px 16px;border-radius:4px');
  console.log('%c Built on: Pure HTML/CSS/JS + AWS architecture mindset', 'color:#FF9900;font-size:12px');
  console.log('%c linkedin.com/in/patrickdiamitani | patrick.diamitani@gmail.com', 'color:#8892B0;font-size:11px');

})();
