
const boxes = document.querySelectorAll('.contentWrapper');
let busy = false;
boxes.forEach((contnet) => {
    const oneko = contnet.querySelector('.oneko-run');
    if (!oneko) return;
    let hovered = false;
    let onekoing = false;
    contnet.addEventListener('mouseenter',() => {
        hovered = true;
        if (busy && !onekoing) return;
        busy = true;
        if (onekoing) return;
        onekoing = true;
        oneko.classList.add('hovered');
        oneko.classList.remove('unhovered');
    });
    contnet.addEventListener('mouseleave', () => {
        hovered = false;
        if (onekoing || !(oneko.classList.contains('hovered'))) return;
        onekoing = true;
        oneko.classList.add('unhovered');
        oneko.classList.remove('hovered');
    });
    oneko.addEventListener('animationend', () => {
        onekoing = false;
        if (!hovered && oneko.classList.contains('hovered')) {
            onekoing = true;
            oneko.classList.add('unhovered');
            oneko.classList.remove('hovered');
            
        } else if (!hovered || (hovered && oneko.classList.contains('unhovered'))){
            oneko.classList.remove('unhovered');
            busy = false;
            if (!hovered) window.dispatchEvent(new CustomEvent('onekoed'));
            
        };

    });
    window.addEventListener('onekoed', () => {
        if (hovered) {
            onekoing = true;
            busy = true;
            oneko.classList.add('hovered');
            oneko.classList.remove('unhovered');
        };
    });
});
