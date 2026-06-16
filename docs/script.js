document.addEventListener("DOMContentLoaded", () => {
    // --- State Variables ---
    let reductionVal = 15; // Percent (0 to 30)
    let curveExponent = 4.0; // 2.5, 4.0, or 6.0

    // --- DOM Elements ---
    const comparisonContainer = document.getElementById("contrast-slider-container");
    const overlaySide = document.getElementById("overlay-side");
    const sliderHandle = document.getElementById("comparison-slider-handle");

    const reductionSlider = document.getElementById("reduction-range");
    const reductionValDisplay = document.getElementById("reduction-val-display");
    const btnT25 = document.getElementById("btn-t-2-5");
    const btnT40 = document.getElementById("btn-t-4-0");
    const btnT60 = document.getElementById("btn-t-6-0");

    const liveCanvas = document.getElementById("live-curve-canvas");

    // Hero Mockup Elements (for syncing UI)
    const uiReductionText = document.getElementById("ui-reduction-text");
    const uiSliderFill = document.querySelector(".ui-slider-fill");
    const uiSliderThumb = document.querySelector(".ui-slider-thumb");
    const uiVisualizerDimmed = document.querySelector(".ui-visualizer-bar .dimmed-overlay");
    const uiVisualizerMarker = document.querySelector(".ui-visualizer-bar .orange-marker");
    const uiVisualizerTriangle = document.querySelector(".ui-visualizer-bar .orange-triangle");
    const uiStatusText = document.querySelector(".status-text");
    const uiFooterInfoGray = document.querySelector(".ui-row.footer-info .info-gray");
    const uiExponentLabel = document.querySelector(".exponent-label");
    const uiSegments = document.querySelectorAll(".ui-segmented-control .segment");
    const uiToggle = document.querySelector(".ui-toggle");

    // Troubleshooting Trigger
    const triggerGatekeeper = document.getElementById("trigger-gatekeeper");
    const gatekeeperBox = document.getElementById("gatekeeper-instructions");


    // ==========================================
    // 1. Interactive Before/After Image Slider
    // ==========================================
    let isDragging = false;

    const setSliderPosition = (clientX) => {
        const rect = comparisonContainer.getBoundingClientRect();
        let x = clientX - rect.left;
        
        // Boundaries
        if (x < 0) x = 0;
        if (x > rect.width) x = rect.width;

        const percent = (x / rect.width) * 100;
        overlaySide.style.width = `${percent}%`;
        sliderHandle.style.left = `${percent}%`;
    };

    // Mouse Events
    sliderHandle.addEventListener("mousedown", () => { isDragging = true; });
    window.addEventListener("mouseup", () => { isDragging = false; });
    window.addEventListener("mousemove", (e) => {
        if (!isDragging) return;
        setSliderPosition(e.clientX);
    });

    // Touch Events (Mobile)
    sliderHandle.addEventListener("touchstart", () => { isDragging = true; });
    window.addEventListener("touchend", () => { isDragging = false; });
    window.addEventListener("touchmove", (e) => {
        if (!isDragging) return;
        if (e.touches.length > 0) {
            setSliderPosition(e.touches[0].clientX);
        }
    });

    // Keep clipped screen width synchronized to container width for perfect sliding effect
    const beforeScreen = overlaySide.querySelector(".simulated-screen");
    if (beforeScreen && comparisonContainer) {
        const resizeObserver = new ResizeObserver(entries => {
            for (let entry of entries) {
                beforeScreen.style.width = `${entry.contentRect.width}px`;
            }
        });
        resizeObserver.observe(comparisonContainer);
    }


    // ==========================================
    // 2. High-Contrast Gamma Curve Canvas
    // ==========================================
    const drawGammaCurve = () => {
        if (!liveCanvas) return;
        const ctx = liveCanvas.getContext("2d");
        
        // Get dimensions
        const dpr = window.devicePixelRatio || 1;
        const width = liveCanvas.clientWidth;
        const height = liveCanvas.clientHeight;
        
        // Setup Retina resolution
        liveCanvas.width = width * dpr;
        liveCanvas.height = height * dpr;
        ctx.scale(dpr, dpr);

        const w = width;
        const h = height;

        // Curve constants (matching Swift code in Whiteout v1.5.3)
        const uSplit = 0.2;
        const tSplit = 0.3;
        const base = 10.0;

        // Map visual ratio u (x axis) to actual input brightness t
        const getT = (u) => {
            if (u < uSplit) {
                const ratio = u / uSplit;
                return (Math.pow(base, ratio) - 1.0) / (base - 1.0) * tSplit;
            } else {
                const ratio = (u - uSplit) / (1.0 - uSplit);
                return tSplit + ratio * (1.0 - tSplit);
            }
        };

        // Clear canvas
        ctx.fillStyle = "#0c0c0e";
        ctx.fillRect(0, 0, w, h);

        // --- 1. Draw Grid Lines ---
        ctx.strokeStyle = "rgba(244, 244, 245, 0.05)";
        ctx.lineWidth = 1;
        ctx.setLineDash([3, 3]);

        // Horizontal grid lines (linear y-axis)
        [0.25, 0.5, 0.75].forEach(yRatio => {
            ctx.beginPath();
            ctx.moveTo(0, h * yRatio);
            ctx.lineTo(w, h * yRatio);
            ctx.stroke();
        });

        // Vertical grid lines (logarithmic below 30%, linear above)
        const verticalTs = [0.1, 0.2, 0.5, 0.75];
        verticalTs.forEach(t => {
            let u;
            if (t < tSplit) {
                const ratio = Math.log10((t / tSplit) * 9.0 + 1.0);
                u = ratio * uSplit;
            } else {
                const ratio = (t - tSplit) / (1.0 - tSplit);
                u = uSplit + ratio * (1.0 - uSplit);
            }
            const x = u * w;
            ctx.beginPath();
            ctx.moveTo(x, 0);
            ctx.lineTo(x, h);
            ctx.stroke();
        });

        // --- 2. Draw Diagonal Baseline (Reference: 100% Unreduced) ---
        ctx.strokeStyle = "rgba(244, 244, 245, 0.2)";
        ctx.lineWidth = 1;
        ctx.setLineDash([2, 2]);
        ctx.beginPath();

        const steps = 120;
        for (let i = 0; i <= steps; i++) {
            const u = i / steps;
            const t = getT(u);
            const x = u * w;
            const y = h - t * h;
            
            if (i === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
        }
        ctx.stroke();

        // --- 3. Draw Actual Reduced Curve ---
        // Map slider percent to reduction factor
        const reductionRatio = reductionVal / 100.0;
        const maxOutput = 1.0 - reductionRatio * 0.3; // Replicates 1.0 - amount * 0.3

        ctx.setLineDash([]); // solid line
        ctx.lineWidth = 2.5;

        // Gradient for curve
        const grad = ctx.createLinearGradient(0, h, w, 0);
        grad.addColorStop(0, "#ff7600");
        grad.addColorStop(1, "#ffcc00");
        ctx.strokeStyle = grad;
        ctx.beginPath();

        for (let i = 0; i <= steps; i++) {
            const u = i / steps;
            const t = getT(u);
            const scaleFactor = 1.0 - Math.pow(t, curveExponent) * (1.0 - maxOutput);
            const outputVal = t * scaleFactor;

            const x = u * w;
            const y = h - outputVal * h;

            if (i === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
        }
        ctx.stroke();

        // --- 4. Draw Endpoint Indicator Dot ---
        if (reductionVal > 0) {
            const endX = w;
            const endY = h - maxOutput * h;

            // Outer glow
            ctx.fillStyle = "rgba(255, 118, 0, 0.3)";
            ctx.beginPath();
            ctx.arc(endX, endY, 6, 0, Math.PI * 2);
            ctx.fill();

            // Inner solid dot
            ctx.fillStyle = "#ff7600";
            ctx.beginPath();
            ctx.arc(endX, endY, 3.5, 0, Math.PI * 2);
            ctx.fill();
        }

        // --- 5. Draw Axis Labels ---
        ctx.fillStyle = "rgba(161, 161, 170, 0.4)";
        ctx.font = "600 8.5px 'JetBrains Mono'";
        ctx.setLineDash([]);
        
        // Y-axis label (Output)
        ctx.save();
        ctx.translate(12, 15);
        ctx.fillText("Output Brightness (출력)", 0, 0);
        ctx.restore();

        // X-axis label (Input)
        ctx.fillText("Input Brightness (입력)", w - 140, h - 8);
    };


    // ==========================================
    // 3. Control Interactions & Syncing
    // ==========================================
    const updatePopoverUI = () => {
        // Sync Reduction Text
        const maxWhitePercent = 100 - Math.round(reductionVal * 0.3);
        
        if (uiReductionText) uiReductionText.textContent = `${reductionVal}%`;
        if (uiStatusText) uiStatusText.textContent = `최대 밝기 ${maxWhitePercent}% 로 제한 중`;
        if (uiFooterInfoGray) uiFooterInfoGray.textContent = `흰색 최대값 ${maxWhitePercent}%`;

        // Sync Popover Slider thumb & track width
        // Slider ranges 0 to 30%, which maps to slider thumb left 0% to 100%
        const sliderRatio = reductionVal / 30; // 0 to 1
        if (uiSliderFill) uiSliderFill.style.width = `${sliderRatio * 100}%`;
        if (uiSliderThumb) uiSliderThumb.style.left = `${sliderRatio * 100}%`;

        // Sync Visualizer Bar Overlay
        // The overlay represents the clipped region from maxWhitePercent to 100%
        const whitepointRatio = maxWhitePercent / 100; // e.g. 0.85
        if (uiVisualizerDimmed) uiVisualizerDimmed.style.width = `${(1 - whitepointRatio) * 100}%`;
        if (uiVisualizerMarker) uiVisualizerMarker.style.left = `${whitepointRatio * 100}%`;
        if (uiVisualizerTriangle) uiVisualizerTriangle.style.left = `${whitepointRatio * 100}%`;

        // Sync Exponent Text
        if (uiExponentLabel) uiExponentLabel.textContent = `T = ${curveExponent.toFixed(1)}`;

        // Sync Segment Controller active styling
        let activeIdx = 0;
        if (curveExponent === 4.0) activeIdx = 1;
        if (curveExponent === 6.0) activeIdx = 2;

        uiSegments.forEach((seg, idx) => {
            if (idx === activeIdx) {
                seg.classList.add("active");
            } else {
                seg.classList.remove("active");
            }
        });

        // Toggle styling on/off based on reduction
        if (reductionVal === 0) {
            uiToggle.classList.remove("active");
            uiStatusText.textContent = "비활성화됨";
            uiStatusText.style.color = "#a1a1aa";
        } else {
            uiToggle.classList.add("active");
            uiStatusText.style.color = "#ff7600";
        }
    };

    // Reduction Slider Change Event
    reductionSlider.addEventListener("input", (e) => {
        reductionVal = parseInt(e.target.value);
        reductionValDisplay.textContent = `${reductionVal}%`;
        
        drawGammaCurve();
        updatePopoverUI();
    });

    // Exponent T-Value preset select actions
    const setExponent = (newExp) => {
        curveExponent = newExp;
        
        // Update active class on preset button links
        [btnT25, btnT40, btnT60].forEach(btn => {
            const btnVal = parseFloat(btn.getAttribute("data-val"));
            if (btnVal === newExp) {
                btn.classList.add("active");
            } else {
                btn.classList.remove("active");
            }
        });

        // Update active class on text list items
        document.querySelectorAll(".preset-item").forEach(item => {
            const val = parseFloat(item.getAttribute("data-preset"));
            if (val === newExp) {
                item.classList.add("active");
            } else {
                item.classList.remove("active");
            }
        });

        drawGammaCurve();
        updatePopoverUI();
    };

    // Bind Button Clicks
    btnT25.addEventListener("click", () => setExponent(2.5));
    btnT40.addEventListener("click", () => setExponent(4.0));
    btnT60.addEventListener("click", () => setExponent(6.0));

    // Bind Preset List Item Clicks
    document.querySelectorAll(".preset-item").forEach(item => {
        item.addEventListener("click", () => {
            const val = parseFloat(item.getAttribute("data-preset"));
            setExponent(val);
        });
    });

    // Bind Hero UI Popover segments to make them interactive
    uiSegments.forEach((seg, idx) => {
        seg.addEventListener("click", () => {
            let exp = 2.5;
            if (idx === 1) exp = 4.0;
            if (idx === 2) exp = 6.0;
            setExponent(exp);
        });
    });

    // Toggle click inside popover simulation
    uiToggle.addEventListener("click", () => {
        if (reductionVal > 0) {
            // save previous and turn to 0
            uiToggle.dataset.prevVal = reductionVal;
            reductionVal = 0;
        } else {
            reductionVal = parseInt(uiToggle.dataset.prevVal || 15);
        }
        reductionSlider.value = reductionVal;
        reductionValDisplay.textContent = `${reductionVal}%`;
        
        drawGammaCurve();
        updatePopoverUI();
    });


    // ==========================================
    // 4. Troubleshooting Drawer
    // ==========================================
    if (triggerGatekeeper && gatekeeperBox) {
        triggerGatekeeper.addEventListener("click", (e) => {
            e.preventDefault();
            gatekeeperBox.classList.toggle("visible");
            if (gatekeeperBox.classList.contains("visible")) {
                gatekeeperBox.scrollIntoView({ behavior: 'smooth' });
            }
        });
    }


    // --- Init Call ---
    drawGammaCurve();
    updatePopoverUI();

    // Redraw graph when window resizes
    window.addEventListener("resize", drawGammaCurve);
});
