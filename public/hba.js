$(document).ready(function() {
	$('#manual_backup_button').click(function() {
		$(this).attr('disabled', 'disabled');
		$('#ajax_loader').show();
		$('#backup_result').html('');
		callback = function(data) {
			$('#ajax_loader').hide();
			if ('success' == data.status) {
				$('#backup_result').html('Success! Refresh the page to see the new bundle.').addClass('success');
			} else {
				$('#backup_result').html('Error! ' + data.message).addClass('error');
			}
			$('#manual_backup_button').removeAttr("disabled");
		};
		$.post('/', null, callback, 'json');
	});
});