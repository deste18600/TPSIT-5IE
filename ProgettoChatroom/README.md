# Progetto Chatroom 

## Struttura del progetto

Il lavoro è composto da tre progetti distinti ma collegati:

1.  **Server (Dart CLI)**\
    Gestisce tutte le connessioni, smista i messaggi ai client connessi
    e mantiene la lista dei partecipanti.

2.  **Client PC (Dart CLI)**\
    Permette di collegarsi al server da terminale, inviare messaggi e
    riceverli dagli altri utenti.

3.  **Client Mobile (Flutter)**\
    Applicazione grafica che permette agli utenti di unirsi alla
    chatroom tramite smartphone.

------------------------------------------------------------------------

## Funzionamento dei tre progetti

### Server

-   Avvia un socket TCP sulla porta scelta.
-   Accetta ogni nuova connessione.
-   Ogni client viene gestito tramite un oggetto dedicato.
-   I messaggi ricevuti vengono inviati a tutti i client connessi.
-   Gestisce disconnessioni e chiusura del socket.

### Client PC

-   Si collega al server usando indirizzo IP e porta.
-   Permette di scegliere un nome utente.
-   Mostra i messaggi provenienti dagli altri client.
-   Invia messaggi al server che poi li redistribuisce.

### Client Mobile (Flutter)

-   UI con una chat simile a WhatsApp.
-   Si collega tramite socket TCP al server Dart.
-   Mostra tutti i messaggi degli altri utenti.
-   Evita duplicazioni di messaggi locali.
-   Gestisce la disconnessione dell'utente.

------------------------------------------------------------------------

## Metodi e funzionalità principali

### Server

-   **listen()**\
    Attende nuove connessioni.
-   **handleData()**\
    Gestisce i dati ricevuti dal singolo client.
-   **broadcast()**\
    Invia un messaggio a tutti i client.
-   **removeClient()**\
    Rimuove un client disconnesso.

### Client PC

-   **connect()**\
    Apre la connessione verso il server.
-   **stdin.listen()**\
    Gestisce l'input dell'utente.
-   **socket.listen()**\
    Riceve messaggi dal server.

### Client Mobile (Flutter)

-   **Socket.connect()**\
    Apre la connessione TCP.
-   **StreamBuilder**\
    Mostra in tempo reale i messaggi ricevuti.
-   **TextField + Controller**\
    Gestisce l'invio dei messaggi.
-   **setState()**\
    Aggiorna la lista dei messaggi in UI.

------------------------------------------------------------------------