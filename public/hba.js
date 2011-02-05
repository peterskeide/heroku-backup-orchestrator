$(document).ready(function() {
	
	$('#manual_backup_button').click(function() {
		$(this).attr('disabled', 'disabled');
		$('#ajax_loader').show();
		$('#backup_result').html('');

		callback = function(data) {
			$('#ajax_loader').hide();
			if ('success' == data.status) {
				$('#backup_result').html('Success! Refresh the page to see the new bundle.').removeClass('error').addClass('success');
			} else {
				$('#backup_result').html('Error! ' + data.message).removeClass('success').addClass('error');
			}
			$('#manual_backup_button').removeAttr("disabled");
		};
	
		var application_name = $(this).attr('data-application-name');
		$.post('/applications/' + application_name, callback, 'json');
	});
	
});