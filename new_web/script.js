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
    
    let phase = 'typing'; // 'typing' or 'scrolling'
    let actionCounter = 0;
    let ideLinesCount = 0;
    let ideScrollY = 0;
    let browserScrollY = 0;
    
    // Clean initial content
    ideContainers.forEach(c => c.innerHTML = '');
    browserContainers.forEach(c => c.innerHTML = '');
    
    // Helper to generate custom styled elements
    function createIdeLine(widthPercent, colorClass) {
        const line = document.createElement('div');
        line.className = `ide-code-line ${colorClass}`;
        line.style.width = '0';
        line.style.opacity = '0';
        // Animates width and opacity smoothly
        setTimeout(() => {
            line.style.width = `${widthPercent}%`;
            line.style.opacity = '1';
        }, 50);
        return line;
    }
    
    function createBrowserLine(widthPercent) {
        const line = document.createElement('div');
        line.className = 'browser-line';
        line.style.width = `${widthPercent}%`;
        return line;
    }
    
    // Add initial mock IDE lines
    for (let i = 0; i < 5; i++) {
        const width = Math.floor(Math.random() * 50) + 35;
        const colors = ['w-60', 'w-80', 'w-40'];
        const color = colors[Math.floor(Math.random() * colors.length)];
        ideContainers.forEach(container => {
            const line = document.createElement('div');
            line.className = `ide-code-line ${color}`;
            line.style.width = `${width}%`;
            line.style.opacity = '1';
            container.appendChild(line);
        });
        ideLinesCount++;
    }
    
    // Add initial mock Browser lines (12 lines to fill screen)
    for (let i = 0; i < 12; i++) {
        const width = Math.floor(Math.random() * 50) + 35;
        browserContainers.forEach(container => {
            const line = document.createElement('div');
            line.className = 'browser-line';
            line.style.width = `${width}%`;
            container.appendChild(line);
        });
    }
    
    function addIdeLine() {
        const width = Math.floor(Math.random() * 50) + 35;
        const colors = ['w-60', 'w-80', 'w-40'];
        const color = colors[Math.floor(Math.random() * colors.length)];
        
        // Append identical line to all IDE containers in sync
        ideContainers.forEach(container => {
            const line = createIdeLine(width, color);
            container.appendChild(line);
        });
        
        ideLinesCount++;
        
        // Scroll up if we have more than 6 lines
        if (ideLinesCount > 6) {
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
});
