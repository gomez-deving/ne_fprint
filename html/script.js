let container = document.getElementById('container');
let tablet = document.getElementById('tablet');
let result = document.getElementById('result');
let status = document.getElementById('status');
let resName = document.getElementById('res-name');
let resDob  = document.getElementById('res-dob');
let resId   = document.getElementById('res-id');
let matchText = document.getElementById('matchText');
let closeBtn = document.getElementById('closeBtn');

let scanSound = document.getElementById('scan-sound');
let matchSound = document.getElementById('match-sound');

let autoClose = true;
let autoCloseTime = 5;
let playSounds = true;
let closeTimeout = null;

window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    if (data.action === 'open') {
        autoClose = data.autoClose;
        autoCloseTime = data.autoCloseTime || 5;
        playSounds = data.playSounds;
        openUI();
    }

    if (data.action === 'close') {
        closeUI();
    }

    if (data.action === 'showResult') {
        // play scan sound + transition, then show info
        showScanningThenResult(data);
    }
});

function openUI() {
    container.classList.remove('hidden');
    result.classList.add('hidden');
    status.innerText = "Scanning...";
    if (playSounds) {
        try { scanSound.currentTime = 0; scanSound.play(); } catch(e) {}
    }
}

function closeUI() {
    container.classList.add('hidden');
    result.classList.add('hidden');
    status.innerText = "Ready";
    if (closeTimeout) { clearTimeout(closeTimeout); closeTimeout = null; }
    // tell client to release NUI focus
    fetch(`https://${GetParentResourceName()}/close`, { method: 'POST', body: JSON.stringify({}) });
}

closeBtn.addEventListener('click', () => {
    closeUI();
});

function showScanningThenResult(data) {
    // small delay to simulate scanning
    status.innerText = "Processing fingerprint...";
    result.classList.add('hidden');

    if (playSounds) { try { scanSound.currentTime = 0; scanSound.play(); } catch(e) {} }

    setTimeout(() => {
        // show result
        resName.innerText = data.name || "Unknown";
        resDob.innerText = data.dob || "Unknown";
        resId.innerText  = data.identifier || "Unknown";
        matchText.innerText = data.matchText || "Match Found";

        result.classList.remove('hidden');
        status.innerText = "Match found";

        if (playSounds) { try { matchSound.currentTime = 0; matchSound.play(); } catch(e) {} }

        if (autoClose) {
            if (closeTimeout) clearTimeout(closeTimeout);
            closeTimeout = setTimeout(() => { closeUI(); }, autoCloseTime * 1000);
        }
    }, 1400); // scan duration visible time
}

// Listen for NUI callbacks (close)
window.addEventListener('keydown', function(e) {
    if (e.key === "Escape") {
        // send close to client
        closeUI();
    }
});

// Helper to call back to Lua (close)
function postClose() {
    fetch(`https://${GetParentResourceName()}/close`, { method: 'POST', body: JSON.stringify({}) });
}
