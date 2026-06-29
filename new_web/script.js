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
});
