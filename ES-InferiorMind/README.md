Inferior Mind

Sviluppatore: Simone D’Este

Descrizione del progetto:

Il progetto Inferior Mind è una versione semplificata del gioco Mastermind, e consiste nello scegliere una combinazione di 4 colori, per vincere questa dovrà essere uguale alla combinazione di colori creata dal programma.

Scelte di programmazione:

Uso dell’enum ColorOption:

Nel programma è stato introdotto un enum chiamato ColorOption, che contiene i valori gray, green, red e purple, questo è stato fatto per evitare errori durante l'uso degli switch;

Funzione _generateTarget():
uesta funzione genera casualmente la combinazione segreta di quattro colori che il giocatore dovrà indovinare.
Usa la classe Random per scegliere i colori tra verde, rosso e viola, in modo che ogni partita sia diversa.
Dopo la generazione, i pulsanti del giocatore vengono riportati al colore grigio, pronti per una nuova partita.

Funzione _changeColor()

La funzione _changeColor() si attiva quando il giocatore preme uno dei quattro pulsanti colorati.
Serve per modificare il colore del pulsante seguendo un ciclo: grigio → verde → rosso → viola → grigio.

Funzione _showWinningCondition()

Questa funzione viene eseguita quando l’utente preme il pulsante “Verifica scelta”.
Confronta la combinazione scelta dal giocatore con quella segreta:

se sono identiche, il programma mostra un messaggio con scritto “Hai vinto!”;

se sono diverse, viene mostrato “Non hai indovinato”.

Metodo build():

il metodo build serve per costruire la schermata grafica e aggiornare ciò che l’utente vede.
In questo progetto, il build() crea la struttura dell’interfaccia, composta da:

una barra del titolo nella parte superiore;

una riga con i quattro pulsanti colorati;

un pulsante in basso per verificare la scelta del giocatore.


