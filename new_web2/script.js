document.addEventListener('DOMContentLoaded', () => {
    const slider = document.getElementById('comparisonSlider');
    const panelAfter = document.getElementById('panelAfter');
    const handle = document.getElementById('sliderHandle');
    
    const badgeVal = document.getElementById('sliderBadgeVal');
    const root = document.documentElement;
    
    function updateSliderWidth() {
        const rect = slider.getBoundingClientRect();
        slider.style.setProperty('--slider-width', `${rect.width}px`);
    }
    updateSliderWidth();
    window.addEventListener('resize', updateSliderWidth);

    if (!slider || !panelAfter || !handle) return;
    
    let isDragging = false;

    function applyLiveWhiteout(position) {
        // position: 0 (leftmost) -> 100 (rightmost)
        // t: 0.0 (0% reduction) -> 1.0 (20% reduction)
        const t = Math.max(0, Math.min(1, position / 100));
        const reductionRatio = t * 0.20;
        const pct = Math.round(t * 20);
        
        // Pure Whitepoint Reduction (Neutral Achromatic Gamma Attenuation):
        // Whiteout reduces white luminance purely without color distortion or yellowing.
        // t = 0 (0% reduction): Pure white (#ffffff, rgb(255, 255, 255))
        // t = 1 (20% reduction): Neutral dimmer white (#cccccc, rgb(204, 204, 204))
        const lumMain = Math.round(255 - t * 51); // 255 -> 204
        const bgMain = `rgb(${lumMain}, ${lumMain}, ${lumMain})`;

        // Surface interpolation (248 -> 198, clean neutral grey)
        const lumSurf = Math.round(248 - t * 50);
        const bgSurface = `rgb(${lumSurf}, ${lumSurf}, ${lumSurf})`;

        // Card interpolation (255 -> 208, neutral clean white-to-light-grey)
        const lumCard = Math.round(255 - t * 47);
        const bgCard = `rgb(${lumCard}, ${lumCard}, ${lumCard})`;

        // Border interpolation (226 -> 175)
        const lumBrd = Math.round(226 - t * 51);
        const borderColor = `rgb(${lumBrd}, ${lumBrd}, ${lumBrd})`;

        // Nav Glassmorphism background (neutral transparent white)
        const navBg = `rgba(${lumMain}, ${lumMain}, ${lumMain}, 0.92)`;

        // Browser mock screen background in the hero laptop (Pure White -> Dimmed White)
        const lumBrowser = Math.round(255 - t * 51); // 255 -> 204
        const sliderBrowserBg = `rgb(${lumBrowser}, ${lumBrowser}, ${lumBrowser})`;

        // Dynamic Glare and Shield opacities
        const glareOpacity = (1 - t).toFixed(3);
        const shieldOpacity = Math.min(1, t * 1.6).toFixed(3);

        // Update CSS Variables on Root
        root.style.setProperty('--reduction-ratio', reductionRatio.toFixed(2));
        root.style.setProperty('--white-reduction-pct', `${pct}%`);
        root.style.setProperty('--bg-main', bgMain);
        root.style.setProperty('--bg-surface', bgSurface);
        root.style.setProperty('--bg-card', bgCard);
        root.style.setProperty('--border-color', borderColor);
        root.style.setProperty('--nav-bg', navBg);
        root.style.setProperty('--slider-browser-bg', sliderBrowserBg);
        root.style.setProperty('--glare-opacity', glareOpacity);
        root.style.setProperty('--shield-opacity', shieldOpacity);

        // Update handle badge display
        if (badgeVal) {
            badgeVal.textContent = pct === 0 ? '0%' : `-${pct}%`;
        }
    }
    
    function moveSlider(x) {
        const rect = slider.getBoundingClientRect();
        let position = ((x - rect.left) / rect.width) * 100;
        
        // Clamp position between 0% and 100%
        if (position < 0) position = 0;
        if (position > 100) position = 100;
        
        // Apply position to slider UI via clip-path and handle left
        panelAfter.style.clipPath = `polygon(0 0, ${position}% 0, ${position}% 100%, 0 100%)`;
        panelAfter.style.webkitClipPath = `polygon(0 0, ${position}% 0, ${position}% 100%, 0 100%)`;
        handle.style.left = `${position}%`;

        // Apply real-time Whiteout to entire webpage & mock screens
        applyLiveWhiteout(position);
    }

    // Initialize with 50% slider position (10% reduction) and set inline styles
    panelAfter.style.clipPath = 'polygon(0 0, 50% 0, 50% 100%, 0 100%)';
    panelAfter.style.webkitClipPath = 'polygon(0 0, 50% 0, 50% 100%, 0 100%)';
    handle.style.left = '50%';
    applyLiveWhiteout(50);
    
    // Modern unified Pointer and Touch Events for smooth 60fps drag across Mouse, Trackpad, and Touch
    function startDrag(clientX) {
        isDragging = true;
        moveSlider(clientX);
    }

    function onDrag(clientX) {
        if (!isDragging) return;
        moveSlider(clientX);
    }

    function stopDrag() {
        isDragging = false;
    }

    // Pointer events on slider
    slider.addEventListener('pointerdown', (e) => {
        startDrag(e.clientX);
        try {
            slider.setPointerCapture(e.pointerId);
        } catch (err) {}
        e.preventDefault();
    });

    slider.addEventListener('pointermove', (e) => {
        if (!isDragging) return;
        onDrag(e.clientX);
        e.preventDefault();
    });

    slider.addEventListener('pointerup', (e) => {
        stopDrag();
        try {
            slider.releasePointerCapture(e.pointerId);
        } catch (err) {}
    });

    slider.addEventListener('pointercancel', stopDrag);

    // Global window listeners for mouse and touch fallback
    window.addEventListener('mousemove', (e) => {
        if (isDragging) onDrag(e.clientX);
    });

    window.addEventListener('mouseup', stopDrag);

    slider.addEventListener('touchstart', (e) => {
        if (e.touches && e.touches[0]) {
            startDrag(e.touches[0].clientX);
        }
    }, { passive: true });

    window.addEventListener('touchmove', (e) => {
        if (isDragging && e.touches && e.touches[0]) {
            onDrag(e.touches[0].clientX);
        }
    }, { passive: true });

    window.addEventListener('touchend', stopDrag);
    window.addEventListener('touchcancel', stopDrag);
    
    // Optional: Smooth scroll for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            const targetId = this.getAttribute('href');
            if (targetId === '#') return;
            
            const targetElement = document.querySelector(targetId);
            if (targetElement) {
                targetElement.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // --- Infinite Synchronized Mock Web Page Scrolling Simulator ---
    const browserContainers = document.querySelectorAll('.browser-content-mock');
    let browserScrollY = 0;

    function createBrowserLine(widthPercent) {
        const line = document.createElement('div');
        line.className = 'browser-line';
        line.style.width = `${widthPercent}%`;
        return line;
    }

    function addBrowserLine() {
        const width = Math.floor(Math.random() * 45) + 35;
        browserContainers.forEach(container => {
            const line = createBrowserLine(width);
            container.appendChild(line);
        });

        browserScrollY += 14;
        browserContainers.forEach(container => {
            container.style.transform = `translateY(-${browserScrollY}px)`;
        });

        // Prune old lines seamlessly to prevent infinite DOM expansion
        const firstContainer = browserContainers[0];
        if (firstContainer && firstContainer.children.length > 20) {
            browserContainers.forEach(container => {
                if (container.firstChild) {
                    container.removeChild(container.firstChild);
                }
                container.style.transition = 'none';
                container.style.transform = `translateY(-${browserScrollY - 14}px)`;
                container.offsetHeight;
                container.style.transition = 'transform 0.4s ease-in-out';
            });
            browserScrollY -= 14;
        }
    }

    setInterval(addBrowserLine, 1200);
});

// ─── i18n: Language-based content switching + manual toggle ───────────────
(function initI18n() {
    // Determine initial language (browser detection, overridable by user)
    const storedLang = localStorage.getItem('whiteout_lang');
    let currentLang = storedLang || (window.__isKorean ? 'ko' : 'en');

    function applyLang(lang) {
        currentLang = lang;
        localStorage.setItem('whiteout_lang', lang);
        document.documentElement.lang = lang;

        const attr = lang === 'ko' ? 'data-ko' : 'data-en';

        // Switch all elements with data-ko / data-en attributes
        document.querySelectorAll('[data-ko],[data-en]').forEach(el => {
            const text = el.getAttribute(attr);
            if (text !== null) {
                el.innerHTML = text;
            }
        });

        // Update page title & meta description
        if (lang === 'ko') {
            document.title = 'WhiteOut - GPU 가속 기반 과학적 눈 보호 솔루션';
            const metaDesc = document.querySelector('meta[name="description"]');
            if (metaDesc) metaDesc.setAttribute('content',
                '단순 밝기 조절이 아닙니다. 대비 감도를 100% 보존하면서 눈의 동공 조절 피로를 해소하고 트루 블랙을 지키는 과학적인 화이트포인트 관리 유틸리티, WhiteOut.');
        } else {
            document.title = 'WhiteOut - GPU-Level Eye Strain Prevention for Mac';
            const metaDesc = document.querySelector('meta[name="description"]');
            if (metaDesc) metaDesc.setAttribute('content',
                'Simply dimming your screen is not the cure. WhiteOut controls white point photon energy directly at the GPU hardware level, preserving 100% contrast and true blacks while eliminating digital eye strain.');
        }

        // Highlight the active language in the toggle button
        document.querySelectorAll('.lang-opt').forEach(opt => {
            opt.classList.toggle('active', opt.dataset.lang === lang);
        });
    }

    // Wire up toggle button: clicking either EN or KR span switches language
    const toggleBtn = document.getElementById('langToggle');
    if (toggleBtn) {
        toggleBtn.addEventListener('click', e => {
            const opt = e.target.closest('.lang-opt');
            if (opt) {
                applyLang(opt.dataset.lang);
            } else {
                // Clicking the button itself (not a span) toggles
                applyLang(currentLang === 'ko' ? 'en' : 'ko');
            }
        });
    }

    // Apply on load
    applyLang(currentLang);
})();
