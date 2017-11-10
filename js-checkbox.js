$(document).ready(function(){
  $('input[type=checkbox]').on('click', function(event){
    if($('input[type=checkbox]:checked').length < 3){
      $(this).prop('checked', true);
    }
  });
});