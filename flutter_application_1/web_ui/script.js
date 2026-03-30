// Provide a dynamic interactive feel for the primary button on click
function nextStep() {
    const btn = document.querySelector('.primary-button');
    const icon = btn.querySelector('.btn-icon');
    const text = btn.querySelector('.btn-text');
    
    // Add simple state feedback indicating a loading transition
    btn.style.pointerEvents = 'none'; // Disable click
    text.textContent = 'Continuing...';
    
    // Switch icon to a loading spinner
    icon.className = 'ri-loader-4-line ri-spin btn-icon';
    
    // Simulate async operation like navigating next step
    setTimeout(() => {
        // Success state
        icon.className = 'ri-check-line btn-icon';
        text.textContent = 'Success!';
        btn.style.backgroundColor = '#10b981'; // vibrant green
        btn.style.boxShadow = '0 8px 16px rgba(16, 185, 129, 0.4)';
        
        // Reset after short delay to show micro-interaction again
        setTimeout(() => {
            icon.className = 'ri-arrow-right-line btn-icon';
            text.textContent = 'Get Started';
            btn.style.backgroundColor = '';
            btn.style.boxShadow = '';
            btn.style.pointerEvents = 'auto'; // Re-enable click
        }, 1500);
        
    }, 1000);
}
