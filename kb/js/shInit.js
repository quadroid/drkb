var attempts = 0;
var timerHandle = setTimeout("checkIfHilighterLoaded()", 350);

function checkIfHilighterLoaded(){
  try{
    dp.SyntaxHighlighter.ClipboardSwf = '/flash/clipboard.swf';      
    dp.SyntaxHighlighter.HighlightAll('code');    

    clearTimeout(timerHandle);
  }
  catch(e){
    clearTimeout(timerHandle);
     if(attempts < 25){
      timerHandle = setTimeout("checkIfHilighterLoaded()", 350);
    }
     attempts++;
  }
}