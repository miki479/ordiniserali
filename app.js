import { initializeApp } from "https://www.gstatic.com/firebasejs/10.14.0/firebase-app.js";
import { getFirestore, collection, addDoc, getDocs, getDoc, setDoc, deleteDoc, updateDoc, doc, query, where, runTransaction } from "https://www.gstatic.com/firebasejs/10.14.0/firebase-firestore.js";
import { getAuth, signInWithEmailAndPassword, createUserWithEmailAndPassword, signOut, onAuthStateChanged, updateProfile } from "https://www.gstatic.com/firebasejs/10.14.0/firebase-auth.js";

const firebaseConfig = {
  apiKey: "AIzaSyAExuqHi74XLGzGalZAlZTPMNtIPJ8zjyQ",
  authDomain: "ordiniserali.firebaseapp.com",
  projectId: "ordiniserali",
  storageBucket: "ordiniserali.appspot.com",
  messagingSenderId: "60228923319",
  appId: "1:60228923319:web:98ded014014aee07b78232",
  measurementId: "G-5KKLKNGTM5"
};
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const auth = getAuth(app);

// ---------- shared UI helpers (replace alert/confirm/prompt) ----------
function toast(msg) {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.classList.add('show');
  clearTimeout(toast._t);
  toast._t = setTimeout(() => t.classList.remove('show'), 2600);
}

function openOverlay(id) { document.getElementById(id).classList.add('active'); }
function closeOverlay(id) { document.getElementById(id).classList.remove('active'); }

function customConfirm(title, text) {
  return new Promise(resolve => {
    document.getElementById('confirm-title').textContent = title;
    document.getElementById('confirm-text').textContent = text;
    openOverlay('confirm-overlay');
    const yes = document.getElementById('confirm-yes');
    const no = document.getElementById('confirm-no');
    function cleanup(result) {
      closeOverlay('confirm-overlay');
      yes.removeEventListener('click', onYes);
      no.removeEventListener('click', onNo);
      resolve(result);
    }
    function onYes() { cleanup(true); }
    function onNo() { cleanup(false); }
    yes.addEventListener('click', onYes);
    no.addEventListener('click', onNo);
  });
}

document.addEventListener('click', (e) => {
  const closeId = e.target.getAttribute && e.target.getAttribute('data-close');
  if (closeId) closeOverlay(closeId);
});

document.getElementById('info-trigger').addEventListener('click', () => openOverlay('disclaimer-overlay'));

// ---------- normalizzazione identità ----------
// "Mario", "mario", "MARIO", " Mario " diventano tutti la stessa identità: "Mario"
function normalizeName(str) {
  return (str || '')
    .replace(/[^a-zA-Z\u00C0-\u017F\s'\-\.\u2019\u2018\u0060\u00B4]/g, '') // via emoji, numeri, simboli: solo lettere e ' - .
    .replace(/[\u2019\u2018\u0060\u00B4]/g, "'")   // apostrofi tipografici/backtick -> apostrofo semplice
    .replace(/\s*'\s*/g, "'")                        // niente spazi attorno all'apostrofo (D' Amico -> D'Amico)
    .replace(/\s*-\s*/g, '-')                        // idem per i trattini
    .trim().replace(/\s+/g, ' ')
    .toLowerCase()
    // Maiuscola dopo inizio parola, apostrofo e trattino: d'amico -> D'Amico, gian-luca -> Gian-Luca
    .replace(/(^|[\s'\-])([a-zà-ú])/g, (m, sep, ch) => sep + ch.toUpperCase());
}

function slugify(str) {
  return (str || '').trim().toLowerCase()
    .normalize('NFD').replace(/[\u0300-\u036f]/g, '') // rimuove accenti
    .replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '') || 'x';
}

// Ogni account ha una "email" tecnica derivata da nome+cognome (Firebase Auth la richiede,
// ma nessuno la vede o la usa: si accede sempre con nome, cognome e password).
function pseudoEmail(nome, cognome) {
  return `${slugify(cognome)}.${slugify(nome)}@vicomeal.local`;
}

function pulisciTesto(str) {
  return (str || '')
    .replace(/[^\u0020-\u00FF\n]/g, '')  // via emoji e simboli esotici: nel PDF diventerebbero caratteri illeggibili
    .replace(/[ \t]+/g, ' ')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

const MAX_ORDINE_LENGTH = 300;

// Avvolge una promessa con un tempo massimo: su rete lenta/assente meglio un errore chiaro
// che un'attesa infinita in cui l'utente non sa se l'ordine è partito o no.
function withTimeout(promise, ms) {
  return Promise.race([
    promise,
    new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), ms))
  ]);
}

// Banner ben visibile quando manca la rete: senza, un invio fallito in silenzio
// farebbe credere all'utente di aver ordinato quando non è vero.
function aggiornaStatoRete() {
  const banner = document.getElementById('offline-banner');
  if (banner) banner.hidden = navigator.onLine;
}
window.addEventListener('online', aggiornaStatoRete);
window.addEventListener('offline', aggiornaStatoRete);

// Trascina verso il basso dall'inizio della pagina per ricaricare lo stato degli ordini
// (utile per vedere subito se il capolinea ha chiuso la giornata, senza riaprire l'app).
function attivaPullToRefresh(onRefresh) {
  const ind = document.createElement('div');
  ind.id = 'ptr-indicator';
  ind.textContent = '↻';
  document.body.appendChild(ind);

  let startY = null;
  let attivo = false;
  const SOGLIA = 75;

  window.addEventListener('touchstart', (e) => {
    if (window.scrollY <= 0) { startY = e.touches[0].clientY; attivo = false; }
    else startY = null;
  }, { passive: true });

  window.addEventListener('touchmove', (e) => {
    if (startY === null) return;
    const delta = e.touches[0].clientY - startY;
    if (delta > 25) ind.classList.add('visibile');
    attivo = delta > SOGLIA;
  }, { passive: true });

  window.addEventListener('touchend', async () => {
    if (startY === null) return;
    startY = null;
    if (!attivo) { ind.classList.remove('visibile'); return; }
    ind.classList.add('girando');
    try { await onRefresh(); } catch (e) { console.error(e); }
    ind.classList.remove('girando');
    ind.classList.remove('visibile');
  }, { passive: true });
}

document.addEventListener('DOMContentLoaded', function () {
  aggiornaStatoRete();
  attivaPullToRefresh(async () => {
    // Ha senso solo dentro l'app: ricarica lo stato ordini (giornata chiusa, ordine adottato, ecc.)
    // e i ruoli (capolinea/superuser possono essere cambiati da un altro account nel frattempo:
    // senza questo, chi viene promosso capolinea vedrebbe il pannello solo rifacendo il login).
    if (!menuSection.hidden && auth.currentUser) {
      await Promise.all([caricaOrdineDiOggi(), aggiornaRuoli(auth.currentUser)]);
      toast('Aggiornato.');
    }
  });
  const loadingScreen = document.getElementById('loading-screen');
  const loginScreen = document.getElementById('login-screen');
  const welcomeBackScreen = document.getElementById('welcome-back-screen');
  const authForm = document.getElementById('auth-form');
  const menuSection = document.getElementById('menu');
  const eliminaOrdiniBtn = document.getElementById('elimina-ordini');
  const scaricaPdfBtn = document.getElementById('scarica-pdf');
  const logoutBtn = document.getElementById('logout-btn');
  const panelTrigger = document.getElementById('panel-trigger');
  const capolineaZone = document.getElementById('capolinea-zone');

  const ordineInput = document.getElementById('ordine-personalizzato');
  const orderForm = document.getElementById('order-form');
  const lockedOverlay = document.getElementById('locked-overlay');
  const accompRow = document.getElementById('accomp-row');
  const ticketBody = document.getElementById('ticket-body');
  const ticketStatus = document.getElementById('ticket-status');
  const sendBtn = document.getElementById('effettua-ordine');
  const stamp = document.getElementById('stamp');

  let accompagnamentoSelezionato = ""; // selezione nel modulo (bozza)
  let savedOrdine = "";                // ciò che è realmente salvato oggi (mostrato in comanda)
  let savedAccompagnamento = "";
  let myOrderDocId = null;
  let myOrderVersione = 1;
  let myOrderLocked = false;
  let sonoSuperUser = false; // solo il superuser può promuovere/rimuovere i capilinea dal pannello

  function getGiornoOggi() {
    const d = new Date();
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  }

  // ==================== AUTENTICAZIONE (account reale per tutti) ====================

  let modalitaLogin = false; // false = crea account, true = accedi con account esistente

  const nomeInput = document.getElementById('nome');
  const cognomeInput = document.getElementById('cognome');
  const passwordInput = document.getElementById('password');
  const confermaInput = document.getElementById('conferma-password');
  const authSubmitBtn = document.getElementById('auth-submit-btn');

  function mostraStep(el, visibile) {
    const eraNascosto = el.classList.contains('step-hidden');
    el.classList.toggle('step-hidden', !visibile);
    if (visibile && eraNascosto) {
      el.classList.add('step-reveal');
      setTimeout(() => el.classList.remove('step-reveal'), 300);
    }
  }

  // I campi compaiono uno alla volta, man mano che compili il precedente
  function aggiornaStepForm() {
    const nomeOk = nomeInput.value.trim().length > 0;
    const cognomeOk = cognomeInput.value.trim().length > 0;
    const passOk = passwordInput.value.length >= 6;
    const confOk = confermaInput.value.length >= 6;

    mostraStep(cognomeInput, nomeOk);
    mostraStep(passwordInput, nomeOk && cognomeOk);
    mostraStep(confermaInput, !modalitaLogin && nomeOk && cognomeOk && passOk);
    mostraStep(authSubmitBtn, modalitaLogin ? (nomeOk && cognomeOk && passOk) : (nomeOk && cognomeOk && passOk && confOk));
  }

  [nomeInput, cognomeInput, passwordInput, confermaInput].forEach(el => {
    el.addEventListener('input', aggiornaStepForm);
  });

  function aggiornaModalitaAuth() {
    document.getElementById('auth-submit-btn').textContent = modalitaLogin ? 'Accedi →' : 'Crea account e entra →';
    document.getElementById('auth-mode-sub').textContent = modalitaLogin ? 'Accedi con le tue credenziali' : 'Crea il tuo account per ordinare';
    document.getElementById('toggle-auth-mode').textContent = modalitaLogin ? 'Non hai un account? Registrati' : 'Hai già un account? Accedi';
    aggiornaStepForm();
  }

  // I due percorsi dell'overlay "questo nome esiste già"
  document.getElementById('omonimo-accedi').addEventListener('click', () => {
    closeOverlay('omonimo-overlay');
    modalitaLogin = true;
    aggiornaModalitaAuth();
    // Nome e cognome restano compilati: manca solo la password
    document.getElementById('password').value = '';
    document.getElementById('password').focus();
  });

  document.getElementById('omonimo-iniziale').addEventListener('click', () => {
    closeOverlay('omonimo-overlay');
    const nomeInput = document.getElementById('nome');
    nomeInput.value = nomeInput.value.trim() + ' ';
    nomeInput.focus();
    toast('Aggiungi la tua iniziale dopo il nome, poi ricrea l\'account.');
  });

  document.getElementById('toggle-auth-mode').addEventListener('click', () => {
    modalitaLogin = !modalitaLogin;
    aggiornaModalitaAuth();
  });

  function salvaProfiloLocale(nome, cognome) {
    localStorage.setItem('profiloVisuale', JSON.stringify({ nome, cognome }));
  }

  function leggiProfiloLocale() {
    const raw = localStorage.getItem('profiloVisuale');
    if (!raw) return null;
    try { return JSON.parse(raw); } catch (e) { return null; }
  }

  // Ricontrolla capolinea/superuser su Firestore e aggiorna i pulsanti di conseguenza.
  // Usata sia all'ingresso nell'app sia dal pull-to-refresh, così una promozione fatta
  // da un altro account si vede senza dover rifare il login.
  async function aggiornaRuoli(user) {
    let isCapolinea = false;
    try {
      const capSnap = await getDoc(doc(db, 'capolinea_autorizzati', user.uid));
      isCapolinea = capSnap.exists();
    } catch (e) { console.error(e); }

    sonoSuperUser = false;
    try {
      const superSnap = await getDoc(doc(db, 'superuser_autorizzati', user.uid));
      sonoSuperUser = superSnap.exists();
    } catch (e) { console.error(e); }

    mostraPulsantiDipendente(isCapolinea, sonoSuperUser);
    return isCapolinea;
  }

  // Firebase può notificare lo stato di login più di una volta durante l'avvio (prima con
  // la cache locale, poi confermato dal server): senza questa guardia, due chiamate quasi
  // simultanee finivano entrambe qui, ognuna con la propria query, e il suggerimento
  // "ordina di nuovo" appariva doppio (o mancava, a seconda di chi finiva per ultimo).
  let ingressoAppInCorso = false;

  // Punto di ingresso unico nell'app, una volta che sappiamo chi è l'utente autenticato
  async function entraNellApp(user, nome, cognome) {
    if (ingressoAppInCorso) return;
    ingressoAppInCorso = true;
    try {
      salvaProfiloLocale(nome, cognome);
      const isCapolinea = await aggiornaRuoli(user);
      welcomeBackScreen.hidden = true;
      loginScreen.hidden = true;
      menuSection.hidden = false;
      document.getElementById('username').textContent = `${nome} ${cognome}`.trim() || 'Nome non disponibile';
      await caricaOrdineDiOggi();

      // Pulizia automatica: gli ordini più vecchi di 3 mesi vengono eliminati.
      // Parte quando un capolinea apre l'app (solo loro hanno i permessi di cancellazione),
      // al massimo una volta al giorno per dispositivo.
      if (isCapolinea) cleanupVecchiOrdini();
    } finally {
      ingressoAppInCorso = false;
    }
  }

  async function cleanupVecchiOrdini() {
    if (localStorage.getItem('ultimaPulizia') === getGiornoOggi()) return;
    localStorage.setItem('ultimaPulizia', getGiornoOggi());
    try {
      const cutoff = new Date(Date.now() - 90 * 24 * 3600 * 1000);
      const cutoffStr = `${cutoff.getFullYear()}-${String(cutoff.getMonth() + 1).padStart(2, '0')}-${String(cutoff.getDate()).padStart(2, '0')}`;
      const qVecchi = query(collection(db, 'ordini'), where('giorno', '<', cutoffStr));
      const snap = await getDocs(qVecchi);
      if (!snap.empty) await Promise.all(snap.docs.map(d => deleteDoc(d.ref)));
      // Pulisce anche i "lucchetti giornata" ormai inutili
      const giorniSnap = await getDocs(collection(db, 'giorni'));
      const vecchiGiorni = giorniSnap.docs.filter(d => d.id < cutoffStr);
      if (vecchiGiorni.length) await Promise.all(vecchiGiorni.map(d => deleteDoc(d.ref)));
    } catch (e) { console.error(e); }
  }

  // ==================== APPRENDIMENTO PREFERENZE ====================
  // Analizza gli ordini passati (ultimi 3 mesi, poi vengono eliminati) cercando la
  // parola-piatto più ricorrente: "grigliata mista con zucchine" e "grigliata e patatine"
  // condividono "grigliata", che è il piatto vero al netto delle varianti.

  const STOPWORDS_ORDINE = new Set([
    'con', 'e', 'ed', 'al', 'alla', 'allo', 'ai', 'agli', 'alle', 'di', 'del', 'della',
    'dello', 'dei', 'degli', 'delle', 'da', 'in', 'su', 'per', 'senza', 'no', 'non',
    'un', 'una', 'uno', 'il', 'lo', 'la', 'le', 'i', 'gli', 'ben', 'poco', 'poca',
    'molto', 'molta', 'extra', 'doppia', 'doppio', 'tanto', 'tanta', 'piu', 'solo',
    'anche', 'oppure', 'cotta', 'cotto', 'bene'
  ]);

  async function calcolaPiattoFrequente(uid) {
    try {
      const qMiei = query(collection(db, 'ordini'), where('uid', '==', uid));
      const snap = await getDocs(qMiei);
      const conteggi = {};
      const esempi = {};
      snap.forEach(d => {
        const testo = d.data().ordine || '';
        const giorno = d.data().giorno || '';
        // Parole uniche per ordine: "grigliata" conta 1 anche se ripetuta nello stesso testo
        const parole = new Set(
          testo.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '')
            .split(/[^a-z]+/)
            .filter(w => w.length >= 4 && !STOPWORDS_ORDINE.has(w))
        );
        parole.forEach(w => {
          conteggi[w] = (conteggi[w] || 0) + 1;
          // Ricorda la variante più recente contenente questa parola, per precompilare
          if (!esempi[w] || giorno >= esempi[w].giorno) {
            esempi[w] = { testo, giorno, accompagnamento: d.data().accompagnamento || '' };
          }
        });
      });
      let migliore = null;
      for (const [parola, count] of Object.entries(conteggi)) {
        if (count >= 7 && (!migliore || count > migliore.count)) {
          migliore = { parola, count, ...esempi[parola] };
        }
      }
      return migliore;
    } catch (e) { console.error(e); return null; }
  }

  function mostraPulsantiDipendente(isCapolinea, isSuperUser) {
    capolineaZone.hidden = !isCapolinea;
    panelTrigger.hidden = !isCapolinea;
    document.getElementById('status').textContent = isCapolinea ? (isSuperUser ? 'CAPOLINEA · SUPERUSER' : 'CAPOLINEA') : '';
  }

  // Reagisce ad ogni cambio di sessione Firebase Auth (login, logout, sessione già attiva al refresh)
  onAuthStateChanged(auth, async (user) => {
    loadingScreen.hidden = true;
    if (user) {
      // Se l'utente è già dentro l'app (es. appena entrato dal modulo di accesso),
      // non mostriamo la schermata "Sei tu?" sopra al menu: serve solo alle riaperture.
      if (!menuSection.hidden) return;

      let profilo = leggiProfiloLocale();
      if (!profilo) {
        try {
          const uSnap = await getDoc(doc(db, 'utenti', user.uid));
          if (uSnap.exists()) { profilo = uSnap.data(); salvaProfiloLocale(profilo.nome, profilo.cognome); }
        } catch (e) { console.error(e); }
      }

      // La conferma "Sei tu?" appare solo ogni tanto (7 giorni dall'ultima conferma),
      // non ad ogni apertura: abbastanza spesso da intercettare un cambio di persona
      // sul dispositivo, abbastanza raro da non diventare fastidiosa.
      const GIORNI_TRA_CONFERME = 7;
      const ultimaConferma = parseInt(localStorage.getItem('ultimaConfermaIdentita') || '0', 10);
      const confermaRecente = (Date.now() - ultimaConferma) < GIORNI_TRA_CONFERME * 24 * 3600 * 1000;

      if (profilo && profilo.cognome && confermaRecente) {
        entraNellApp(user, profilo.nome, profilo.cognome);
        return;
      }

      document.getElementById('welcome-back-name').textContent = profilo ? `Ciao, ${profilo.nome} ${profilo.cognome}` : 'Bentornato';
      loginScreen.hidden = true;
      menuSection.hidden = true;
      welcomeBackScreen.hidden = false;

      document.getElementById('welcome-back-yes').onclick = async () => {
        if (!profilo || !profilo.cognome) {
          toast('Non riesco a recuperare il tuo profilo. Accedi di nuovo.');
          localStorage.removeItem('profiloVisuale');
          try { await signOut(auth); } catch (e) { console.error(e); }
          return;
        }
        localStorage.setItem('ultimaConfermaIdentita', String(Date.now()));
        entraNellApp(user, profilo.nome, profilo.cognome);
      };
    } else {
      welcomeBackScreen.hidden = true;
      menuSection.hidden = true;
      loginScreen.hidden = false;
    }
  });

  document.getElementById('welcome-back-no').addEventListener('click', async function () {
    localStorage.removeItem('profiloVisuale');
    try { await signOut(auth); } catch (e) { console.error(e); }
    // onAuthStateChanged si occuperà di mostrare la schermata di accesso
  });

  authForm.addEventListener('submit', async function (event) {
    event.preventDefault();
    const nome = normalizeName(document.getElementById('nome').value);
    const cognome = normalizeName(document.getElementById('cognome').value);
    const password = document.getElementById('password').value;
    if (/\s/.test(password)) { toast('La password non può contenere spazi.'); return; }
    if (/[^\x21-\x7E]/.test(password)) { toast('Nella password usa solo lettere, numeri e simboli standard: niente emoji o lettere accentate, alcune tastiere le scrivono in modo diverso e non riusciresti più ad accedere.'); return; }
    const email = pseudoEmail(nome, cognome);

    const submitBtn = document.getElementById('auth-submit-btn');
    const etichettaOriginale = submitBtn.textContent;
    submitBtn.disabled = true;
    submitBtn.textContent = modalitaLogin ? 'Accesso...' : 'Creazione account...';

    try {
      let userCredential;
      if (modalitaLogin) {
        userCredential = await signInWithEmailAndPassword(auth, email, password);
      } else {
        const conferma = document.getElementById('conferma-password').value;
        if (password !== conferma) {
          toast('Le due password non coincidono.');
          submitBtn.disabled = false; submitBtn.textContent = etichettaOriginale;
          return;
        }
        if (password.length < 6) {
          toast('La password deve avere almeno 6 caratteri.');
          submitBtn.disabled = false; submitBtn.textContent = etichettaOriginale;
          return;
        }
        userCredential = await createUserWithEmailAndPassword(auth, email, password);
        try { await setDoc(doc(db, 'utenti', userCredential.user.uid), { nome, cognome }); } catch (e) { console.error(e); }
      }
      authForm.reset();
      aggiornaStepForm();
      submitBtn.disabled = false;
      submitBtn.textContent = etichettaOriginale;
      localStorage.setItem('ultimaConfermaIdentita', String(Date.now()));
      await entraNellApp(userCredential.user, nome, cognome);
    } catch (error) {
      console.error(error);
      if (error.code === 'auth/email-already-in-use') {
        document.getElementById('omonimo-testo').textContent =
          `Esiste già un account "${nome} ${cognome}". Se sei tu, accedi con la tua password.`;
        openOverlay('omonimo-overlay');
      } else if (error.code === 'auth/wrong-password' || error.code === 'auth/user-not-found' || error.code === 'auth/invalid-credential') {
        toast('Nome, cognome o password non corretti.');
      } else if (error.code === 'auth/weak-password') {
        toast('Password troppo debole (minimo 6 caratteri).');
      } else {
        toast('Errore: ' + error.message);
      }
      submitBtn.disabled = false;
      submitBtn.textContent = etichettaOriginale;
    }
  });

  logoutBtn.addEventListener('click', async function () {
    const ok = await customConfirm('Uscire?', 'Dovrai reinserire nome, cognome e password al prossimo accesso su questo dispositivo.');
    if (!ok) return;
    localStorage.removeItem('profiloVisuale');
    try { await signOut(auth); } catch (e) { console.error(e); }
  });

  // ==================== MODULO ORDINE ====================

  document.querySelectorAll('#chip-suggestions .chip').forEach(chip => {
    chip.addEventListener('click', () => {
      ordineInput.value = chip.dataset.fill;
      aggiornaStatoBottone();
      ordineInput.focus();
    });
  });

  accompRow.querySelectorAll('.accomp-chip').forEach(c => {
    c.addEventListener('click', () => {
      accompRow.querySelectorAll('.accomp-chip').forEach(x => x.classList.remove('active'));
      c.classList.add('active');
      accompagnamentoSelezionato = c.dataset.value;
      aggiornaStatoBottone();
    });
  });
  accompRow.querySelector('.accomp-chip[data-value=""]').classList.add('active');

  ordineInput.addEventListener('input', aggiornaStatoBottone);
  ordineInput.addEventListener('keyup', aggiornaStatoBottone);

  // Il tasto invia/aggiorna si attiva solo quando c'è davvero qualcosa di nuovo da mandare
  function aggiornaStatoBottone() {
    if (myOrderLocked) { sendBtn.disabled = true; }
    else { sendBtn.disabled = ordineInput.value.trim() === ''; }
    aggiornaTicket();
  }

  // Mentre scrivi, la comanda segue in diretta. Se il campo è vuoto mostra l'ultimo ordine salvato.
  function aggiornaTicket() {
    const testo = ordineInput.value.trim();
    if (testo) {
      renderTicket(testo, accompagnamentoSelezionato);
      ticketStatus.textContent = myOrderDocId ? 'MODIFICA IN CORSO' : 'DA INVIARE';
      return;
    }
    if (savedOrdine) {
      renderTicket(savedOrdine, savedAccompagnamento);
      ticketStatus.textContent = myOrderLocked ? 'CHIUSA' : 'INVIATA';
      return;
    }
    ticketBody.innerHTML = '<span class="empty">Il riepilogo del tuo ordine apparirà qui...</span>';
    ticketStatus.textContent = 'DA INVIARE';
  }

  function renderTicket(testo, accomp) {
    let html = `<div class="line"><span class="arrow">→</span> ${escapeHtml(testo)}</div>`;
    if (accomp) {
      html += `<div class="line"><span class="arrow">→</span> ${escapeHtml(accomp)}</div>`;
    }
    ticketBody.innerHTML = html;
  }

  function escapeHtml(str){
    const d = document.createElement('div');
    d.textContent = str;
    return d.innerHTML;
  }

  // Oscura e disattiva l'intero modulo (chip comprese) quando l'ordine non è più modificabile:
  // pointer-events:none sul contenitore blocca anche i chip di suggerimento, che altrimenti
  // scrivevano comunque nel campo disabilitato perché il valore si può settare via JS.
  function impostaBloccoModulo(bloccato) {
    orderForm.classList.toggle('locked', bloccato);
    lockedOverlay.hidden = !bloccato;
    ordineInput.disabled = bloccato;
  }

  // Pulisce solo il modulo (bozza), lasciando intatta la comanda già salvata
  function puliscibozza() {
    ordineInput.value = '';
    accompagnamentoSelezionato = '';
    accompRow.querySelectorAll('.accomp-chip').forEach(x => x.classList.remove('active'));
    accompRow.querySelector('.accomp-chip[data-value=""]').classList.add('active');
    sendBtn.disabled = true;
  }

  // Reset completo: nessun ordine salvato oggi, modulo pulito
  function resetOrderForm() {
    puliscibozza();
    impostaBloccoModulo(false);
    savedOrdine = '';
    savedAccompagnamento = '';
    aggiornaTicket();
    stamp.style.display = 'none';
    sendBtn.style.display = 'block';
    sendBtn.textContent = 'Invia comanda';
    myOrderDocId = null;
    myOrderLocked = false;
  }

  // Rientranza: se una chiamata è già in corso (es. arriva da più punti quasi insieme:
  // avvio app, pull-to-refresh, eliminazione ordini), le successive non fanno nulla invece
  // di sovrapporsi e lasciare tracce doppie nel suggerimento "ordina di nuovo".
  let caricamentoOrdineInCorso = false;

  async function caricaOrdineDiOggi() {
    if (!auth.currentUser || caricamentoOrdineInCorso) return;
    caricamentoOrdineInCorso = true;
    try {
      await caricaOrdineDiOggiInterno();
    } finally {
      caricamentoOrdineInCorso = false;
    }
  }

  async function caricaOrdineDiOggiInterno() {
    const uid = auth.currentUser.uid;
    const profilo = leggiProfiloLocale() || {};
    const oggi = getGiornoOggi();
    const repeatSlot = document.getElementById('repeat-order-slot');
    const docId = `${oggi}_${uid}`;
    let docSnap;
    try { docSnap = await getDoc(doc(db, 'ordini', docId)); } catch (e) { console.error(e); return; }

    // ADOZIONE ORDINI OSPITE: se qualcuno ha già ordinato per te oggi ("Ordina per un collega")
    // prima che tu avessi un account, quell'ordine esiste come "ospite" col tuo nome.
    // Lo riconosciamo e lo colleghiamo al tuo account, così non risulti mai due volte nel PDF.
    if (!docSnap.exists() && profilo.nome && profilo.cognome) {
      const guestId = `${oggi}_ospite_${slugify(profilo.cognome)}_${slugify(profilo.nome)}`;
      try {
        const guestSnap = await getDoc(doc(db, 'ordini', guestId));
        if (guestSnap.exists()) {
          docSnap = guestSnap;
          // Colleghiamo l'account all'ordine (solo se non è già bloccato dal PDF)
          if (!guestSnap.data().bloccato && !guestSnap.data().uid) {
            try { await updateDoc(doc(db, 'ordini', guestId), { uid }); } catch (e) { console.error(e); }
          }
        }
      } catch (e) { console.error(e); }
    }

    if (!docSnap.exists()) {
      resetOrderForm();
      let giornoChiuso = false;
      try {
        const giornoSnap = await getDoc(doc(db, 'giorni', oggi));
        giornoChiuso = giornoSnap.exists() && giornoSnap.data().bloccato === true;
      } catch (e) { console.error(e); }

      if (giornoChiuso) {
        repeatSlot.innerHTML = '';
        impostaBloccoModulo(true);
        sendBtn.style.display = 'none';
        stamp.textContent = 'ORDINI CHIUSI PER OGGI';
        stamp.style.display = 'block';
        ticketStatus.textContent = 'CHIUSA';
        ticketBody.innerHTML = '<span class="empty">La comanda di stasera è già partita. Si riordina domani.</span>';
      } else {
        await mostraSuggerimentoRipeti(uid);
        impostaBloccoModulo(false);
      }
      return;
    }

    repeatSlot.innerHTML = '';
    const data = docSnap.data();
    myOrderDocId = docSnap.id;
    myOrderVersione = data.versione || 1;
    myOrderLocked = !!data.bloccato;

    savedOrdine = data.ordine || '';
    savedAccompagnamento = data.accompagnamento || '';
    puliscibozza(); // il modulo resta pulito: la comanda sopra basta a mostrare cosa hai ordinato
    aggiornaTicket();

    impostaBloccoModulo(myOrderLocked);

    if (myOrderLocked) {
      sendBtn.style.display = 'none';
      stamp.textContent = '✓ ORDINE INVIATO AL RISTORANTE';
      stamp.style.display = 'block';
    } else {
      sendBtn.style.display = 'block';
      sendBtn.textContent = 'Aggiorna comanda';
      stamp.style.display = 'none';
    }
  }

  async function mostraSuggerimentoRipeti(uid) {
    const repeatSlot = document.getElementById('repeat-order-slot');
    repeatSlot.innerHTML = '';

    // Suggerimento 1: l'ultimo ordine esatto (salvato sul dispositivo)
    let ultimo = null;
    const raw = localStorage.getItem(`ultimoOrdine_${uid}`);
    if (raw) { try { ultimo = JSON.parse(raw); } catch (e) { ultimo = null; } }
    if (ultimo && !ultimo.ordine) ultimo = null;

    // Suggerimento 2: il piatto ricorrente (>= 7 volte negli ultimi 3 mesi)
    const frequente = await calcolaPiattoFrequente(uid);

    // Si alternano un giorno sì e uno no quando esistono entrambi
    let scelta = null;
    if (ultimo && frequente) scelta = (new Date().getDate() % 2 === 0) ? 'frequente' : 'ultimo';
    else if (frequente) scelta = 'frequente';
    else if (ultimo) scelta = 'ultimo';
    if (!scelta) return;

    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'repeat-chip';

    if (scelta === 'frequente') {
      const piatto = frequente.parola.charAt(0).toUpperCase() + frequente.parola.slice(1);
      btn.innerHTML = `<span class="ico">🔥</span><span>Ordinato molte volte: <strong>${escapeHtml(piatto)}</strong></span>`;
      btn.addEventListener('click', () => {
        ordineInput.value = frequente.testo;
        accompagnamentoSelezionato = frequente.accompagnamento || '';
        accompRow.querySelectorAll('.accomp-chip').forEach(x => {
          x.classList.toggle('active', x.dataset.value === accompagnamentoSelezionato);
        });
        aggiornaStatoBottone();
        toast('Precompilato con la tua ultima variante: controlla e invia.');
      });
    } else {
      const riepilogo = ultimo.accompagnamento ? `${ultimo.ordine} + ${ultimo.accompagnamento}` : ultimo.ordine;
      btn.innerHTML = `<span class="ico">🔁</span><span>Ordina di nuovo: <strong>${escapeHtml(riepilogo)}</strong></span>`;
      btn.addEventListener('click', () => {
        ordineInput.value = ultimo.ordine;
        accompagnamentoSelezionato = ultimo.accompagnamento || '';
        accompRow.querySelectorAll('.accomp-chip').forEach(x => {
          x.classList.toggle('active', x.dataset.value === accompagnamentoSelezionato);
        });
        aggiornaStatoBottone();
        toast('Ordine precompilato: controlla e invia.');
      });
    }
    repeatSlot.appendChild(btn);
  }

  sendBtn.addEventListener('click', async function () {
    if (!auth.currentUser) { toast('Devi accedere prima di ordinare.'); return; }
    const uid = auth.currentUser.uid;
    const profilo = leggiProfiloLocale() || {};

    const testo = pulisciTesto(ordineInput.value);
    if (!testo) { toast('Scrivi il tuo ordine prima di inviare.'); return; }
    if (testo.length > MAX_ORDINE_LENGTH) { toast(`Ordine troppo lungo (max ${MAX_ORDINE_LENGTH} caratteri).`); return; }
    if (myOrderLocked) { toast('Il tuo ordine è già stato inviato e non è più modificabile.'); return; }

    const oggi = getGiornoOggi();
    // Se hai già un ordine oggi (anche "adottato" da un ordine ospite fatto per te),
    // le modifiche vanno su quello: mai crearne un secondo con un altro ID.
    const docId = myOrderDocId || `${oggi}_${uid}`;
    const ref = doc(db, 'ordini', docId);
    const versioneAttesa = myOrderVersione;

    sendBtn.disabled = true;
    const etichettaOriginale = sendBtn.textContent;
    sendBtn.textContent = 'Invio...';
    try {
      await withTimeout(runTransaction(db, async (tx) => {
        const snap = await tx.get(ref);
        if (snap.exists()) {
          const current = snap.data();
          if (current.bloccato) { throw new Error('locked'); }
          if ((current.versione || 1) !== versioneAttesa) { throw new Error('conflict'); }
          tx.update(ref, {
            ordine: testo,
            accompagnamento: accompagnamentoSelezionato || null,
            versione: (current.versione || 1) + 1
          });
        } else {
          const giornoSnap = await tx.get(doc(db, 'giorni', oggi));
          if (giornoSnap.exists() && giornoSnap.data().bloccato) { throw new Error('giorno-chiuso'); }
          tx.set(ref, {
            uid: uid,
            nome: profilo.nome || '',
            cognome: profilo.cognome || '',
            ordine: testo,
            accompagnamento: accompagnamentoSelezionato || null,
            giorno: oggi,
            bloccato: false,
            versione: 1
          });
        }
      }), 15000);

      myOrderDocId = docId;
      myOrderVersione = versioneAttesa + 1;

      localStorage.setItem(`ultimoOrdine_${uid}`, JSON.stringify({
        ordine: testo,
        accompagnamento: accompagnamentoSelezionato || null
      }));

      savedOrdine = testo;
      savedAccompagnamento = accompagnamentoSelezionato || '';

      stamp.textContent = '✓ ORDINE INVIATO';
      stamp.style.display = 'block';
      sendBtn.style.display = 'none';
      puliscibozza();
      aggiornaTicket();
      setTimeout(() => {
        stamp.style.display = 'none';
        sendBtn.style.display = 'block';
        sendBtn.textContent = 'Aggiorna comanda';
      }, 2600);
    } catch (error) {
      if (error.message === 'conflict') {
        toast('Il tuo ordine è stato modificato nel frattempo (es. da un altro dispositivo). Ricarico la versione più recente.');
        await caricaOrdineDiOggi();
      } else if (error.message === 'locked') {
        toast('Il tuo ordine è già stato inviato e non è più modificabile.');
        await caricaOrdineDiOggi();
      } else if (error.message === 'giorno-chiuso') {
        toast('Il servizio ordini di oggi è chiuso: il capolinea ha già inviato la comanda.');
        await caricaOrdineDiOggi();
      } else if (error.message === 'timeout') {
        toast('La rete è lenta o assente: l\'ordine NON risulta inviato. Controlla la connessione e riprova.');
        sendBtn.disabled = false;
        sendBtn.textContent = etichettaOriginale;
      } else {
        console.error("Errore durante l'invio dell'ordine: ", error);
        toast('Errore nell\'invio dell\'ordine: NON risulta inviato. Riprova.');
        sendBtn.disabled = false;
        sendBtn.textContent = etichettaOriginale;
      }
    }
  });

  // ==================== ZONA CAPOLINEA ====================

  eliminaOrdiniBtn.addEventListener('click', async function () {
    if (!auth.currentUser) { toast('Devi accedere prima.'); return; }
    const ok = await customConfirm('Eliminare gli ordini di oggi?', 'Questa azione è irreversibile e riguarda gli ordini di tutti per la giornata odierna. Verrà registrato il tuo account.');
    if (!ok) return;
    let snapshot;
    try {
      const q = query(collection(db, 'ordini'), where('giorno', '==', getGiornoOggi()));
      snapshot = await getDocs(q);
      await Promise.all(snapshot.docs.map(d => deleteDoc(d.ref)));
    } catch (e) {
      console.error(e);
      toast('Errore durante l\'eliminazione: alcuni ordini potrebbero essere rimasti. Riprova.');
      return;
    }

    // Riapre anche la giornata: eliminare tutto serve a ripartire da zero,
    // quindi togliamo il lucchetto messo dal download del PDF (se c'era).
    try { await deleteDoc(doc(db, 'giorni', getGiornoOggi())); } catch (e) { console.error(e); }

    try {
      await addDoc(collection(db, 'eliminazioni_log'), {
        account: auth.currentUser.email,
        uid: auth.currentUser.uid,
        data: new Date()
      });
    } catch (e) { console.error(e); }
    toast('Ordini di oggi eliminati. Il servizio ordini è di nuovo aperto.');
    caricaOrdineDiOggi();
  });

  scaricaPdfBtn.addEventListener('click', async function () {
    if (scaricaPdfBtn.disabled) return;
    scaricaPdfBtn.disabled = true;
    const etichettaOriginale = scaricaPdfBtn.textContent;
    scaricaPdfBtn.textContent = '⏳ Generazione PDF...';
    // Apriamo la scheda SUBITO, prima di qualsiasi attesa: è l'unico momento in cui il browser
    // riconosce con certezza che l'apertura è una risposta diretta al tocco, e non la blocca.
    const nuovaScheda = window.open('', '_blank');
    try {
    const { jsPDF } = window.jspdf;
    const pdfDoc = new jsPDF();
    const margin = 15;
    let y = margin;
    pdfDoc.setFontSize(12);
    pdfDoc.text("Ordini del giorno:", margin, y); y += 10;
    pdfDoc.setFontSize(10);
    pdfDoc.text("Cognome", margin, y);
    pdfDoc.text("Ordine", margin + 50, y);
    pdfDoc.text("Accompagnamento", margin + 130, y);
    y += 10;

    const q = query(collection(db, 'ordini'), where('giorno', '==', getGiornoOggi()));
    const snapshot = await getDocs(q);
    const docsOrdinati = snapshot.docs.slice().sort((a, b) => {
      const chiaveA = `${a.data().cognome || ''} ${a.data().nome || ''}`;
      const chiaveB = `${b.data().cognome || ''} ${b.data().nome || ''}`;
      return chiaveA.localeCompare(chiaveB, 'it');
    });
    let n = 1;
    const maxW = 70;
    docsOrdinati.forEach(d => {
      const data = d.data();
      const cognome = data.cognome || "Sconosciuto";
      const ordine = data.ordine || "Nessun ordine";
      const accomp = data.accompagnamento || "Nessuno";
      const of = pdfDoc.splitTextToSize(ordine, maxW);
      const af = pdfDoc.splitTextToSize(accomp, maxW);
      pdfDoc.setFontSize(10);
      pdfDoc.text(`${n}. ${cognome}`, margin, y);
      pdfDoc.text(of, margin + 50, y);
      pdfDoc.text(af, margin + 130, y);
      y += 6 * Math.max(of.length, af.length);
      if (y > 270) { pdfDoc.addPage(); y = margin; }
      n++;
    });
    if (y < 270) {
      y = 270;
    } else {
      pdfDoc.addPage();
      y = margin;
    }
    pdfDoc.setFontSize(12);
    pdfDoc.text(`PRENOTAZIONE PER LE ORE 19:30 N.PASTI (${snapshot.size}) + PANE`, margin, y);

    const nomeFile = `comanda_${getGiornoOggi()}.pdf`;
    const pdfBlob = pdfDoc.output('blob');

    // Su telefono condividiamo il file PDF vero (es. su WhatsApp arriva come allegato).
    // Senza questo, l'unica alternativa è aprire un link blob:// che fuori dal browser
    // di chi l'ha generato non porta a nulla: chi lo riceve non può aprirlo.
    let condiviso = false;
    if (navigator.canShare) {
      try {
        const file = new File([pdfBlob], nomeFile, { type: 'application/pdf' });
        if (navigator.canShare({ files: [file] })) {
          if (nuovaScheda) nuovaScheda.close();
          await navigator.share({ files: [file], title: 'Comanda del giorno' });
          condiviso = true;
        }
      } catch (shareError) {
        if (shareError.name === 'AbortError') {
          condiviso = true; // condivisione annullata di proposito: non apriamo comunque una scheda
        } else {
          console.error(shareError);
        }
      }
    }

    if (!condiviso) {
      const blobUrl = URL.createObjectURL(pdfBlob);
      if (nuovaScheda) {
        nuovaScheda.location.href = blobUrl;
      } else {
        const tentativo2 = window.open(blobUrl, '_blank');
        if (!tentativo2) {
          toast('Il browser ha bloccato l\'apertura automatica. Controlla le impostazioni popup, oppure riprova.');
        }
      }
    }

    // Blocca tutti gli ordini di oggi: sono già stati inviati al ristorante, non più modificabili
    try {
      await Promise.all(snapshot.docs.map(d => updateDoc(d.ref, { bloccato: true })));
      await setDoc(doc(db, 'giorni', getGiornoOggi()), { bloccato: true, bloccatoIl: Date.now() });
    } catch (e) { console.error(e); }
    if (myOrderDocId) myOrderLocked = true;
    caricaOrdineDiOggi();

    toast(condiviso ? 'PDF generato.' : 'PDF generato: usa Condividi per salvarlo.');
    } catch (e) {
      console.error(e);
      if (nuovaScheda) { try { nuovaScheda.close(); } catch (e2) {} }
      toast('Errore nella generazione del PDF.');
    } finally {
      scaricaPdfBtn.disabled = false;
      scaricaPdfBtn.textContent = etichettaOriginale;
    }
  });

  // ==================== PANNELLO CAPOLINEA ====================

  panelTrigger.addEventListener('click', () => {
    openOverlay('pannello-overlay');
    caricaPannelloOrdini();
    caricaPannelloUtenti();
  });

  document.querySelectorAll('.pannello-tab').forEach(tab => {
    tab.addEventListener('click', () => {
      document.querySelectorAll('.pannello-tab').forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      document.getElementById('pannello-ordini-tab').hidden = tab.dataset.pannelloTab !== 'ordini';
      document.getElementById('pannello-utenti-tab').hidden = tab.dataset.pannelloTab !== 'utenti';
    });
  });

  function pannelloListaMessaggio(container, testo) {
    container.innerHTML = '';
    const span = document.createElement('span');
    span.className = 'empty';
    span.textContent = testo;
    container.appendChild(span);
  }

  async function caricaPannelloOrdini() {
    const lista = document.getElementById('pannello-ordini-lista');
    pannelloListaMessaggio(lista, 'Caricamento...');
    let snap;
    try {
      const q = query(collection(db, 'ordini'), where('giorno', '==', getGiornoOggi()));
      snap = await getDocs(q);
    } catch (e) {
      console.error(e);
      pannelloListaMessaggio(lista, 'Errore nel caricamento degli ordini.');
      return;
    }
    if (snap.empty) { pannelloListaMessaggio(lista, 'Nessun ordine oggi.'); return; }
    const docsOrdinati = snap.docs.slice().sort((a, b) => {
      const chiaveA = `${a.data().cognome || ''} ${a.data().nome || ''}`;
      const chiaveB = `${b.data().cognome || ''} ${b.data().nome || ''}`;
      return chiaveA.localeCompare(chiaveB, 'it');
    });
    lista.innerHTML = '';
    docsOrdinati.forEach(d => lista.appendChild(creaRigaOrdinePannello(d)));
  }

  function creaRigaOrdinePannello(docSnap) {
    const data = docSnap.data();
    const bloccato = !!data.bloccato;

    const row = document.createElement('div');
    row.className = 'pannello-row';

    const head = document.createElement('div');
    head.className = 'pannello-row-head';
    const nomeSpan = document.createElement('strong');
    nomeSpan.textContent = `${data.nome || ''} ${data.cognome || ''}`.trim() || 'Sconosciuto';
    head.appendChild(nomeSpan);
    if (bloccato) {
      const badge = document.createElement('span');
      badge.className = 'badge-locked';
      badge.textContent = 'BLOCCATO';
      head.appendChild(badge);
    }
    row.appendChild(head);

    const testoInput = document.createElement('input');
    testoInput.type = 'text';
    testoInput.maxLength = MAX_ORDINE_LENGTH;
    testoInput.value = data.ordine || '';
    testoInput.disabled = bloccato;
    row.appendChild(testoInput);

    const accompSelect = document.createElement('select');
    accompSelect.disabled = bloccato;
    [['', 'Nessuno'], ['Pane', '🍞 Pane'], ['Spianata', '🫓 Spianata']].forEach(([val, label]) => {
      const opt = document.createElement('option');
      opt.value = val;
      opt.textContent = label;
      accompSelect.appendChild(opt);
    });
    accompSelect.value = data.accompagnamento || '';
    row.appendChild(accompSelect);

    const actions = document.createElement('div');
    actions.className = 'pannello-row-actions';

    if (!bloccato) {
      const saveBtn = document.createElement('button');
      saveBtn.type = 'button';
      saveBtn.className = 'pannello-btn-save';
      saveBtn.textContent = 'Salva';
      saveBtn.addEventListener('click', async () => {
        const nuovoTesto = pulisciTesto(testoInput.value);
        if (!nuovoTesto) { toast('L\'ordine non può essere vuoto.'); return; }
        if (nuovoTesto.length > MAX_ORDINE_LENGTH) { toast(`Ordine troppo lungo (max ${MAX_ORDINE_LENGTH} caratteri).`); return; }
        saveBtn.disabled = true;
        try {
          await updateDoc(doc(db, 'ordini', docSnap.id), {
            ordine: nuovoTesto,
            accompagnamento: accompSelect.value || null,
            versione: (data.versione || 1) + 1
          });
          toast('Ordine aggiornato.');
          if (docSnap.id === myOrderDocId) caricaOrdineDiOggi();
          caricaPannelloOrdini();
        } catch (e) {
          console.error(e);
          toast('Errore nel salvataggio.');
          saveBtn.disabled = false;
        }
      });
      actions.appendChild(saveBtn);
    }

    const delBtn = document.createElement('button');
    delBtn.type = 'button';
    delBtn.className = 'pannello-btn-delete';
    delBtn.textContent = 'Elimina';
    delBtn.addEventListener('click', async () => {
      const ok = await customConfirm('Eliminare questo ordine?', `L'ordine di ${nomeSpan.textContent} verrà rimosso definitivamente.`);
      if (!ok) return;
      delBtn.disabled = true;
      try {
        await deleteDoc(doc(db, 'ordini', docSnap.id));
        toast('Ordine eliminato.');
        if (docSnap.id === myOrderDocId) caricaOrdineDiOggi();
        caricaPannelloOrdini();
      } catch (e) {
        console.error(e);
        toast('Errore nell\'eliminazione.');
        delBtn.disabled = false;
      }
    });
    actions.appendChild(delBtn);

    row.appendChild(actions);
    return row;
  }

  async function caricaPannelloUtenti() {
    const lista = document.getElementById('pannello-utenti-lista');
    pannelloListaMessaggio(lista, 'Caricamento...');
    let utentiSnap;
    try {
      utentiSnap = await getDocs(collection(db, 'utenti'));
    } catch (e) {
      console.error(e);
      pannelloListaMessaggio(lista, 'Errore nel caricamento degli utenti.');
      return;
    }
    // La lista capolinea può essere protetta da regole più restrittive di "utenti":
    // se non è leggibile, mostriamo comunque gli utenti ma senza il controllo capolinea.
    let capolineaIds = null;
    try {
      const capSnap = await getDocs(collection(db, 'capolinea_autorizzati'));
      capolineaIds = new Set(capSnap.docs.map(d => d.id));
    } catch (e) { console.error(e); }

    if (utentiSnap.empty) { pannelloListaMessaggio(lista, 'Nessun utente registrato.'); return; }
    const utentiOrdinati = utentiSnap.docs.slice().sort((a, b) => {
      const chiaveA = `${a.data().cognome || ''} ${a.data().nome || ''}`;
      const chiaveB = `${b.data().cognome || ''} ${b.data().nome || ''}`;
      return chiaveA.localeCompare(chiaveB, 'it');
    });
    lista.innerHTML = '';
    utentiOrdinati.forEach(d => lista.appendChild(creaRigaUtentePannello(d, capolineaIds)));
  }

  function creaRigaUtentePannello(docSnap, capolineaIds) {
    const data = docSnap.data();
    const uid = docSnap.id;

    const row = document.createElement('div');
    row.className = 'pannello-row';

    const nomeInputPannello = document.createElement('input');
    nomeInputPannello.type = 'text';
    nomeInputPannello.maxLength = 40;
    nomeInputPannello.placeholder = 'Nome';
    nomeInputPannello.value = data.nome || '';
    row.appendChild(nomeInputPannello);

    const cognomeInputPannello = document.createElement('input');
    cognomeInputPannello.type = 'text';
    cognomeInputPannello.maxLength = 40;
    cognomeInputPannello.placeholder = 'Cognome';
    cognomeInputPannello.value = data.cognome || '';
    row.appendChild(cognomeInputPannello);

    const capLabel = document.createElement('label');
    capLabel.className = 'pannello-cap-toggle';
    const capCheckbox = document.createElement('input');
    capCheckbox.type = 'checkbox';
    let capLabelTesto = 'Capolinea';
    if (!capolineaIds) {
      capCheckbox.disabled = true;
      capLabelTesto = 'Capolinea (non disponibile)';
    } else {
      capCheckbox.checked = capolineaIds.has(uid);
      if (!sonoSuperUser) {
        capCheckbox.disabled = true;
        capLabelTesto = 'Capolinea (solo il superuser può modificarlo)';
      }
    }
    capLabel.appendChild(capCheckbox);
    capLabel.appendChild(document.createTextNode(capLabelTesto));
    row.appendChild(capLabel);

    const actions = document.createElement('div');
    actions.className = 'pannello-row-actions';
    const saveBtn = document.createElement('button');
    saveBtn.type = 'button';
    saveBtn.className = 'pannello-btn-save';
    saveBtn.textContent = 'Salva';
    saveBtn.addEventListener('click', async () => {
      const nuovoNome = normalizeName(nomeInputPannello.value);
      const nuovoCognome = normalizeName(cognomeInputPannello.value);
      if (!nuovoNome || !nuovoCognome) { toast('Nome e cognome non possono essere vuoti.'); return; }
      saveBtn.disabled = true;
      try {
        await updateDoc(doc(db, 'utenti', uid), { nome: nuovoNome, cognome: nuovoCognome });
        if (capolineaIds && sonoSuperUser) {
          const dovrebbeEssereCap = capCheckbox.checked;
          const eraCap = capolineaIds.has(uid);
          if (dovrebbeEssereCap && !eraCap) {
            await setDoc(doc(db, 'capolinea_autorizzati', uid), { assegnatoIl: Date.now() });
          } else if (!dovrebbeEssereCap && eraCap) {
            await deleteDoc(doc(db, 'capolinea_autorizzati', uid));
          }
        }
        toast('Utente aggiornato.');
        // Se l'account modificato è quello loggato ora, aggiorna anche la sessione corrente
        if (auth.currentUser && auth.currentUser.uid === uid) {
          salvaProfiloLocale(nuovoNome, nuovoCognome);
          document.getElementById('username').textContent = `${nuovoNome} ${nuovoCognome}`.trim();
        }
        caricaPannelloUtenti();
      } catch (e) {
        console.error(e);
        toast('Errore nel salvataggio dell\'utente.');
        saveBtn.disabled = false;
      }
    });
    actions.appendChild(saveBtn);
    row.appendChild(actions);
    return row;
  }

  // ==================== ORDINA PER UN COLLEGA ====================

  // Accompagnamento del collega: chip fisse, niente testo libero
  let foryouAccomp = '';
  const foryouAccompRow = document.getElementById('foryou-accomp-row');
  foryouAccompRow.querySelectorAll('.accomp-chip').forEach(c => {
    c.addEventListener('click', () => {
      foryouAccompRow.querySelectorAll('.accomp-chip').forEach(x => x.classList.remove('active'));
      c.classList.add('active');
      foryouAccomp = c.dataset.value;
    });
  });

  document.getElementById('foryou-trigger').addEventListener('click', () => {
    document.getElementById('foryou-nome').value = '';
    document.getElementById('foryou-cognome').value = '';
    document.getElementById('foryou-ordine').value = '';
    foryouAccomp = '';
    foryouAccompRow.querySelectorAll('.accomp-chip').forEach(x => x.classList.remove('active'));
    foryouAccompRow.querySelector('.accomp-chip[data-value=""]').classList.add('active');
    document.getElementById('foryou-scelta-persona').hidden = true;
    document.getElementById('foryou-scelta-lista').innerHTML = '';
    openOverlay('foryou-overlay');
  });

  // Invio vero e proprio, una volta stabilito CHI è il destinatario
  async function inviaOrdineCollega(idIdentita, nomeDest, cognomeDest, ordine) {
    const oggi = getGiornoOggi();
    const docId = `${oggi}_${idIdentita}`;
    const ref = doc(db, 'ordini', docId);
    await withTimeout(runTransaction(db, async (tx) => {
      const snap = await tx.get(ref);
      if (snap.exists()) {
        const current = snap.data();
        if (current.bloccato) { throw new Error('locked'); }
        tx.update(ref, { ordine, accompagnamento: foryouAccomp || null, versione: (current.versione || 1) + 1 });
      } else {
        const giornoSnap = await tx.get(doc(db, 'giorni', oggi));
        if (giornoSnap.exists() && giornoSnap.data().bloccato) { throw new Error('giorno-chiuso'); }
        const dati = {
          nome: nomeDest, cognome: cognomeDest, ordine, accompagnamento: foryouAccomp || null,
          giorno: oggi, bloccato: false, versione: 1
        };
        if (!idIdentita.startsWith('ospite_')) dati.uid = idIdentita;
        tx.set(ref, dati);
      }
    }), 15000);
    toast(`Ordine per ${nomeDest} ${cognomeDest} salvato.`);
    closeOverlay('foryou-overlay');
    caricaOrdineDiOggi(); // nel raro caso in cui il "collega" sia l'account attualmente loggato
  }

  document.getElementById('foryou-submit').addEventListener('click', async () => {
    const nomeCollega = normalizeName(document.getElementById('foryou-nome').value);
    const cognome = normalizeName(document.getElementById('foryou-cognome').value);
    const ordine = pulisciTesto(document.getElementById('foryou-ordine').value);
    if (!nomeCollega) { toast('Inserisci anche il nome, non solo il cognome (per evitare confusione tra omonimi).'); return; }
    if (!cognome) { toast('Inserisci il cognome del collega.'); return; }
    if (!ordine) { toast('Inserisci un ordine.'); return; }
    if (ordine.length > MAX_ORDINE_LENGTH) { toast(`Ordine troppo lungo (max ${MAX_ORDINE_LENGTH} caratteri).`); return; }

    const submitBtn = document.getElementById('foryou-submit');
    submitBtn.disabled = true;
    try {
      // Cerchiamo tutti i registrati con questo cognome, per capire se il nome scritto
      // può riferirsi a più persone (es. "Mario Rossi" quando esistono Mario Rossi E Mario B. Rossi)
      let candidati = [];
      try {
        const qUtente = query(collection(db, 'utenti'), where('cognome', '==', cognome));
        const snapUtente = await getDocs(qUtente);
        snapUtente.forEach(d => {
          const n = d.data().nome || '';
          // Candidato se il nome coincide, o se uno dei due è l'altro con qualcosa in più
          // ("Mario" vs "Mario B."): è lì che nascono gli scambi di persona.
          if (n === nomeCollega || n.startsWith(nomeCollega + ' ') || nomeCollega.startsWith(n + ' ')) {
            candidati.push({ uid: d.id, nome: n });
          }
        });
      } catch (e) { console.error(e); }

      const esatto = candidati.find(c => c.nome === nomeCollega);

      // Caso semplice: un solo candidato, con nome esattamente uguale -> nessuna ambiguità
      if (candidati.length === 1 && esatto) {
        await inviaOrdineCollega(esatto.uid, esatto.nome, cognome, ordine);
        return;
      }
      // Nessun registrato compatibile -> ordine ospite (verrà adottato quando si registrerà)
      if (candidati.length === 0) {
        await inviaOrdineCollega(`ospite_${slugify(cognome)}_${slugify(nomeCollega)}`, nomeCollega, cognome, ordine);
        return;
      }

      // Ambiguità: chiediamo esplicitamente chi è il destinatario
      const lista = document.getElementById('foryou-scelta-lista');
      lista.innerHTML = '';
      candidati.forEach(c => {
        const b = document.createElement('button');
        b.type = 'button';
        b.className = 'overlay-btn neutral';
        b.textContent = `${c.nome} ${cognome}`;
        b.addEventListener('click', async () => {
          document.getElementById('foryou-scelta-persona').hidden = true;
          try { await inviaOrdineCollega(c.uid, c.nome, cognome, ordine); }
          catch (e) { gestisciErroreForyou(e, c.nome, cognome); }
        });
        lista.appendChild(b);
      });
      const bOspite = document.createElement('button');
      bOspite.type = 'button';
      bOspite.className = 'overlay-btn ghost';
      bOspite.textContent = `Nessuno di questi: è "${nomeCollega} ${cognome}", non ancora registrato`;
      bOspite.addEventListener('click', async () => {
        document.getElementById('foryou-scelta-persona').hidden = true;
        try { await inviaOrdineCollega(`ospite_${slugify(cognome)}_${slugify(nomeCollega)}`, nomeCollega, cognome, ordine); }
        catch (e) { gestisciErroreForyou(e, nomeCollega, cognome); }
      });
      lista.appendChild(bOspite);
      document.getElementById('foryou-scelta-persona').hidden = false;
    } catch (e) {
      gestisciErroreForyou(e, nomeCollega, cognome);
    } finally {
      submitBtn.disabled = false;
    }
  });

  function gestisciErroreForyou(e, nomeDest, cognomeDest) {
    if (e.message === 'locked') {
      toast(`${nomeDest} ${cognomeDest} ha già un ordine bloccato oggi: non modificabile.`);
    } else if (e.message === 'giorno-chiuso') {
      toast('Il servizio ordini di oggi è chiuso: la comanda è già partita.');
    } else if (e.message === 'timeout') {
      toast('Rete lenta o assente: l\'ordine NON risulta inviato. Riprova.');
    } else {
      console.error(e);
      toast('Errore nell\'invio dell\'ordine: NON risulta inviato.');
    }
  }
});
