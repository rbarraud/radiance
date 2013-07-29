$(function(){
	// Basic Panel UI
	$("#panel>ul>li>ul").hide();

	$("#panel>ul>li>a").click(function(){
		$("ul", $(this).parent()).stop(true).slideToggle();
	});

	$("#panel>ul>li>ul>li").click(function(){
		$("#panel .active").removeClass("active");
		$(this).addClass("active");
		$(this).parent().parent().addClass("active");
	});

	$("#panel>ul>li>ul>li.active").click().parent().show();

	// Table checkboxes
	$(".select-all").click(function(){
		var checkboxes = $('input[type="checkbox"]', $(this).parent().parent().parent().parent());
		checkboxes.prop("checked", $(this).is(":checked"));
	});

	$(".tablebox table").dataTable({
		"bPaginate": false,
		"bFilter": true,
		"bSort": true,
		"bInfo": false,
	});


	// Complex UI

	function AppViewModel() {

	}

	ko.applyBindings(new AppViewModel());
});