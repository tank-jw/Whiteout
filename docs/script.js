document.addEventListener('DOMContentLoaded', () => {
    const slider = document.getElementById('comparisonSlider');
    const panelAfter = document.getElementById('panelAfter');
    const handle = document.getElementById('sliderHandle');
    
    function updateSliderWidth() {
        const rect = slider.getBoundingClientRect();
        slider.style.setProperty('--slider-width', `${rect.width}px`);
    }
    updateSliderWidth();
    window.addEventListener('resize', updateSliderWidth);

    if (!slider || !panelAfter || !handle) return;
    
    let isDragging = false;
    
    function moveSlider(x) {
        const rect = slider.getBoundingClientRect();
        let position = ((x - rect.left) / rect.width) * 100;
        
        // Clamp position between 0% and 100%
        if (position < 0) position = 0;
        if (position > 100) position = 100;
        
        // Apply position
        panelAfter.style.width = `${position}%`;
        handle.style.left = `${position}%`;
    }
    
    // Mouse events
    slider.addEventListener('mousedown', (e) => {
        isDragging = true;
        moveSlider(e.clientX);
        e.preventDefault(); // Prevent text selection
    });
    
    window.addEventListener('mousemove', (e) => {
        if (!isDragging) return;
        moveSlider(e.clientX);
    });
    
    window.addEventListener('mouseup', () => {
        isDragging = false;
    });
    
    // Touch events for mobile responsiveness
    slider.addEventListener('touchstart', (e) => {
        isDragging = true;
        if (e.touches && e.touches[0]) {
            moveSlider(e.touches[0].clientX);
        }
    });
    
    window.addEventListener('touchmove', (e) => {
        if (!isDragging) return;
        if (e.touches && e.touches[0]) {
            moveSlider(e.touches[0].clientX);
        }
    });
    
    window.addEventListener('touchend', () => {
        isDragging = false;
    });
    
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

    // --- Infinite Synchronized Coding and Scrolling Simulator ---
    const ideContainers = document.querySelectorAll('.ide-code-scroll');
    const browserContainers = document.querySelectorAll('.browser-content-mock');
    const terminalContainers = document.querySelectorAll('.terminal-scroll');
    
    let phase = 'typing'; // 'typing' or 'scrolling'
    let actionCounter = 0;
    let ideLinesCount = 0;
    let ideScrollY = 0;
    let browserScrollY = 0;
    let terminalLinesCount = 0;
    let terminalScrollY = 0;
    
    // Clean initial content
    ideContainers.forEach(c => c.innerHTML = '');
    browserContainers.forEach(c => c.innerHTML = '');
    terminalContainers.forEach(c => c.innerHTML = '');
    
    // Helper to generate VS Code styled tokenized lines
    function generateTokensData() {
        const rand = Math.random();
        let tokens = [];
        if (rand < 0.15) {
            // Comment line
            tokens.push({ width: Math.floor(Math.random() * 30) + 40, type: 'token-comment' });
        } else if (rand < 0.5) {
            // Declaration: const/let x = value
            tokens.push({ width: Math.floor(Math.random() * 8) + 12, type: 'token-keyword' });
            tokens.push({ width: Math.floor(Math.random() * 15) + 18, type: 'token-variable' });
            tokens.push({ width: 8, type: 'token-operator' });
            tokens.push({ width: Math.floor(Math.random() * 15) + 15, type: 'token-value' });
        } else if (rand < 0.8) {
            // Function call: console.log(x) or method()
            tokens.push({ width: Math.floor(Math.random() * 12) + 12, type: 'token-variable' });
            tokens.push({ width: Math.floor(Math.random() * 15) + 20, type: 'token-yellow' });
            tokens.push({ width: Math.floor(Math.random() * 8) + 8, type: 'token-value' });
        } else {
            // Class/Type or Return statement
            tokens.push({ width: Math.floor(Math.random() * 8) + 12, type: 'token-keyword' });
            tokens.push({ width: Math.floor(Math.random() * 15) + 15, type: 'token-type' });
            tokens.push({ width: Math.floor(Math.random() * 10) + 12, type: 'token-variable' });
        }
        return tokens;
    }

    function buildLineFromData(tokensData, animate = true) {
        const line = document.createElement('div');
        line.className = 'ide-code-line';
        line.style.opacity = animate ? '0' : '1';
        
        // Append tokens as spans using the identical tokensData
        tokensData.forEach(tok => {
            const span = document.createElement('span');
            span.className = `code-token ${tok.type}`;
            span.style.width = animate ? '0%' : `${tok.width}%`;
            if (animate) {
                span.style.transition = 'width 0.4s ease-out';
                setTimeout(() => {
                    span.style.width = `${tok.width}%`;
                }, 50);
            }
            line.appendChild(span);
        });
        
        if (animate) {
            setTimeout(() => {
                line.style.opacity = '1';
            }, 50);
        }
        
        return line;
    }
    
    function createBrowserLine(widthPercent) {
        const line = document.createElement('div');
        line.className = 'browser-line';
        line.style.width = `${widthPercent}%`;
        return line;
    }
    
    function createTerminalLine(widthPercent, animate = true) {
        const line = document.createElement('div');
        line.className = 'terminal-line';
        line.style.width = animate ? '0%' : `${widthPercent}%`;
        line.style.opacity = animate ? '0' : '1';
        if (animate) {
            setTimeout(() => {
                line.style.width = `${widthPercent}%`;
                line.style.opacity = '1';
            }, 50);
        }
        return line;
    }
    
    // Add initial mock IDE lines (rendered instantly using synchronized token data)
    for (let i = 0; i < 7; i++) {
        const tokensData = generateTokensData();
        ideContainers.forEach(container => {
            const line = buildLineFromData(tokensData, false);
            container.appendChild(line);
        });
        ideLinesCount++;
    }
    
    // Add initial mock Browser lines (12 lines to fill screen)
    for (let i = 0; i < 12; i++) {
        const width = Math.floor(Math.random() * 50) + 35;
        browserContainers.forEach(container => {
            const line = createBrowserLine(width);
            container.appendChild(line);
        });
    }

    // Add initial mock Terminal lines
    for (let i = 0; i < 4; i++) {
        const width = Math.floor(Math.random() * 45) + 20; // 20% to 65%
        terminalContainers.forEach(container => {
            const line = createTerminalLine(width, false);
            container.appendChild(line);
        });
        terminalLinesCount++;
    }
    
    function addIdeLine() {
        const tokensData = generateTokensData();
        
        // Append identical line to all IDE containers in sync
        ideContainers.forEach(container => {
            const line = buildLineFromData(tokensData, true);
            container.appendChild(line);
        });
        
        ideLinesCount++;
        
        // Scroll up if we have more than 7 lines
        if (ideLinesCount > 7) {
            ideScrollY += 14;
            ideContainers.forEach(container => {
                container.style.transform = `translateY(-${ideScrollY}px)`;
            });
        }
        
        // Prune old lines seamlessly to prevent infinite DOM expansion
        const firstContainer = ideContainers[0];
        if (firstContainer && firstContainer.children.length > 25) {
            ideContainers.forEach(container => {
                if (container.firstChild) {
                    container.removeChild(container.firstChild);
                }
                // Temporarily disable transition during layout shift correction
                container.style.transition = 'none';
                container.style.transform = `translateY(-${ideScrollY - 14}px)`;
                container.offsetHeight; // trigger reflow
                container.style.transition = 'transform 0.4s ease-in-out';
            });
            ideScrollY -= 14;
        }
    }
    
    function addBrowserLine() {
        const width = Math.floor(Math.random() * 50) + 35;
        
        // Append identical browser line to all containers
        browserContainers.forEach(container => {
            const line = createBrowserLine(width);
            container.appendChild(line);
        });
        
        // Scroll up by one line height
        browserScrollY += 14;
        browserContainers.forEach(container => {
            container.style.transform = `translateY(-${browserScrollY}px)`;
        });
        
        // Prune old browser lines seamlessly
        const firstContainer = browserContainers[0];
        if (firstContainer && firstContainer.children.length > 25) {
            browserContainers.forEach(container => {
                if (container.firstChild) {
                    container.removeChild(container.firstChild);
                }
                container.style.transition = 'none';
                container.style.transform = `translateY(-${browserScrollY - 14}px)`;
                container.offsetHeight; // trigger reflow
                container.style.transition = 'transform 0.4s ease-in-out';
            });
            browserScrollY -= 14;
        }
    }

    function addTerminalLog() {
        const width = Math.floor(Math.random() * 45) + 20; // 20% to 65%
        
        // Append identical terminal line to all containers in sync
        terminalContainers.forEach(container => {
            const line = createTerminalLine(width, true);
            container.appendChild(line);
        });
        
        terminalLinesCount++;
        
        // Scroll terminal up if it has more than 5 lines
        if (terminalLinesCount > 5) {
            terminalScrollY += 8; // 4px height + 4px margin-bottom
            terminalContainers.forEach(container => {
                container.style.transform = `translateY(-${terminalScrollY}px)`;
            });
        }
        
        // Prune old terminal lines seamlessly
        const firstContainer = terminalContainers[0];
        if (firstContainer && firstContainer.children.length > 15) {
            terminalContainers.forEach(container => {
                if (container.firstChild) {
                    container.removeChild(container.firstChild);
                }
                container.style.transition = 'none';
                container.style.transform = `translateY(-${terminalScrollY - 8}px)`;
                container.offsetHeight; // trigger reflow
                container.style.transition = 'transform 0.3s ease-in-out';
            });
            terminalScrollY -= 8;
        }
    }
    
    // Alternate typing and scrolling infinitely
    setInterval(() => {
        if (phase === 'typing') {
            addIdeLine();
            actionCounter++;
            if (actionCounter >= 7) {
                phase = 'scrolling';
                actionCounter = 0;
            }
        } else {
            addBrowserLine();
            actionCounter++;
            if (actionCounter >= 7) {
                phase = 'typing';
                actionCounter = 0;
            }
        }
    }, 900);

    // Run terminal logs continuously and independently
    setInterval(addTerminalLog, 1400);
});
