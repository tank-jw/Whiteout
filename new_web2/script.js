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

    // --- Live Transfer Curve Monitor Widget (Oscilloscope) ---
    const curveCanvas = document.getElementById('liveCurveCanvas');
    const curveSlider = document.getElementById('curveReductionRange');
    const curveSliderVal = document.getElementById('curveSliderVal');
    const curveModeBtns = document.querySelectorAll('.curve-mode-btn');

    if (curveCanvas) {
        let currentExp = 2.5;
        let currentReduction = curveSlider ? parseInt(curveSlider.value, 10) : 20;

        const uSplit = 0.2;
        const tSplit = 0.3;
        const base = 10.0;

        function getT(u) {
            if (u < uSplit) {
                const ratio = u / uSplit;
                return (Math.pow(base, ratio) - 1.0) / (base - 1.0) * tSplit;
            } else {
                const ratio = (u - uSplit) / (1.0 - uSplit);
                return tSplit + ratio * (1.0 - tSplit);
            }
        }

        function drawCurve() {
            const ctx = curveCanvas.getContext('2d');
            if (!ctx) return;

            const dpr = window.devicePixelRatio || 1;
            const rect = curveCanvas.getBoundingClientRect();
            const w = rect.width;
            const h = rect.height;

            if (w === 0 || h === 0) return;

            curveCanvas.width = w * dpr;
            curveCanvas.height = h * dpr;
            ctx.scale(dpr, dpr);

            ctx.clearRect(0, 0, w, h);

            // Padding around graph area for crisp visuals
            const padX = 14;
            const padY = 16;
            const graphW = w - padX * 2;
            const graphH = h - padY * 2;

            // 1. Grid Lines
            ctx.strokeStyle = 'rgba(255, 255, 255, 0.07)';
            ctx.lineWidth = 1;
            ctx.setLineDash([3, 3]);

            // Horizontal grid lines
            [0.25, 0.5, 0.75].forEach(ratio => {
                const y = padY + graphH * (1 - ratio);
                ctx.beginPath();
                ctx.moveTo(padX, y);
                ctx.lineTo(padX + graphW, y);
                ctx.stroke();
            });

            // Vertical grid lines
            [0.1, 0.2, 0.5, 0.75].forEach(t => {
                let u;
                if (t < tSplit) {
                    const ratio = Math.log10((t / tSplit) * 9.0 + 1.0);
                    u = ratio * uSplit;
                } else {
                    const ratio = (t - tSplit) / (1.0 - tSplit);
                    u = uSplit + ratio * (1.0 - tSplit);
                }
                const x = padX + u * graphW;
                ctx.beginPath();
                ctx.moveTo(x, padY);
                ctx.lineTo(x, padY + graphH);
                ctx.stroke();
            });

            // 2. Unreduced Baseline Reference (Diagonal y = x)
            ctx.strokeStyle = 'rgba(255, 255, 255, 0.22)';
            ctx.lineWidth = 1;
            ctx.setLineDash([2, 2]);
            ctx.beginPath();
            const steps = 80;
            for (let i = 0; i <= steps; i++) {
                const u = i / steps;
                const t = getT(u);
                const x = padX + u * graphW;
                const y = padY + graphH * (1 - t);
                if (i === 0) ctx.moveTo(x, y);
                else ctx.lineTo(x, y);
            }
            ctx.stroke();
            ctx.setLineDash([]); // Reset dash

            // 3. Calculate Transfer Curve Points
            const maxOutput = 1.0 - (currentReduction / 100.0);
            const exp = currentExp;

            const points = [];
            for (let i = 0; i <= steps; i++) {
                const u = i / steps;
                const t = getT(u);
                const sf = 1.0 - Math.pow(t, exp) * (1.0 - maxOutput);
                const finalVal = t * sf;
                const x = padX + u * graphW;
                const y = padY + graphH * (1 - finalVal);
                points.push({ x, y, finalVal });
            }

            // 4. Gradient Fill Under the Curve
            const grad = ctx.createLinearGradient(0, padY, 0, padY + graphH);
            grad.addColorStop(0, 'rgba(245, 158, 11, 0.26)');
            grad.addColorStop(1, 'rgba(245, 158, 11, 0.01)');

            ctx.fillStyle = grad;
            ctx.beginPath();
            ctx.moveTo(points[0].x, points[0].y);
            for (let i = 1; i < points.length; i++) {
                ctx.lineTo(points[i].x, points[i].y);
            }
            ctx.lineTo(padX + graphW, padY + graphH);
            ctx.lineTo(padX, padY + graphH);
            ctx.closePath();
            ctx.fill();

            // 5. Curve Line Stroke with Glow
            ctx.shadowColor = 'rgba(245, 158, 11, 0.45)';
            ctx.shadowBlur = 10;
            ctx.strokeStyle = '#f59e0b';
            ctx.lineWidth = 2.5;
            ctx.lineCap = 'round';
            ctx.lineJoin = 'round';

            ctx.beginPath();
            ctx.moveTo(points[0].x, points[0].y);
            for (let i = 1; i < points.length; i++) {
                ctx.lineTo(points[i].x, points[i].y);
            }
            ctx.stroke();

            // Reset shadow
            ctx.shadowColor = 'transparent';
            ctx.shadowBlur = 0;

            // 6. Suppressed Peak White Endpoint Indicator Dot
            const peak = points[points.length - 1];
            ctx.fillStyle = '#f59e0b';
            ctx.beginPath();
            ctx.arc(peak.x, peak.y, 4, 0, Math.PI * 2);
            ctx.fill();

            ctx.strokeStyle = '#ffffff';
            ctx.lineWidth = 1.5;
            ctx.stroke();

            // Peak badge text
            ctx.font = '600 10px monospace';
            ctx.fillStyle = '#fbbf24';
            ctx.textAlign = 'right';
            const peakPct = Math.round(maxOutput * 100);
            ctx.fillText(`${peakPct}% White`, padX + graphW - 8, peak.y - 8);
        }

        // Event Listeners for Curve Controls
        if (curveSlider) {
            curveSlider.addEventListener('input', (e) => {
                currentReduction = parseInt(e.target.value, 10);
                if (curveSliderVal) {
                    curveSliderVal.textContent = `${currentReduction}%`;
                }
                drawCurve();
            });
        }

        curveModeBtns.forEach(btn => {
            btn.addEventListener('click', () => {
                curveModeBtns.forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                currentExp = parseFloat(btn.dataset.exp) || 2.5;
                drawCurve();
            });
        });

        // Initial render & resize handler
        drawCurve();
        window.addEventListener('resize', drawCurve);
    }
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
