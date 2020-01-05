function updateUI() {
  $.getJSON('api.pl?action=getNP', function(data) {
    console.log(data);

    if (data.status && data.status == "ok") {
      $("#songTitle").html(data.title);
      $("#songArtist").html(data.artist);
      $("#songURL").html("<a href='"+data.streamURL+"'><i class='fa fa-wifi'></i></a> "+data.streamURL);
      $("#ppButton").addClass('fa-pause');
      $("#ppButton").removeClass('fa-play');
    } else {
      $("#songTitle").html("Not Playing");
      $("#songArtist").html('');


      $("#ppButton").addClass("fa-play");
      $("#ppButton").removeClass("fa-pause");
    }
  });
}

$(document).ready(function() {
  $.getJSON('api.pl?action=getNP', function(data) {
    $("input[type=range]").val(data.volume);
  })
  setInterval(function() { updateUI(); }, 2500);
});

$('body').on('click','.fa-play',function(e){

  // Handle start playback

  $(this).addClass('fa-pause')
  $(this).removeClass('fa-play');

  $.getJSON("api.pl?action=start", function(data) {
    console.log(data);
  });
});

$('body').on('click','.fa-pause',function(){

  // Stop

  $(this).addClass('fa-play')
  $(this).removeClass('fa-pause');

  $.getJSON("api.pl?action=stop", function(data) {
    console.log(data);
  });
});

$('body').on('click','input[type=range]',function(){
  // Handle volume control

  var vol = $("input[type=range]").val();
  $.getJSON("api.pl?action=setVolume&volume="+vol, function(data) {
    console.log(data);
  });

});



$('body').on('click','.fa-music',function(){
  $('.song_list').slideToggle();
});

function updateCurrentTime(){
  setInterval(function(){
    var time = audio.currentTime;
    var minutes = Math.floor(time / 60);
    var seconds = Math.floor(time);
    seconds = (seconds - (minutes * 60 )) < 10 ? ('0' + (seconds - (minutes * 60 ))) : (seconds - (minutes * 60 ));
    var currentTime = minutes + ':' + seconds;
    $('.runing_time').text(currentTime);
    $("input[type=range]").val(time/audioTotalTime )
  },1000)

}
