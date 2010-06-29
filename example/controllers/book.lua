local books = {
	{name = "The Bible"};
}

function view(id)
	if not id then
		serveText("Book ID not specified!")
	else
	    book = books[tonumber(id)]
	end
end

function add()
	--no view
end

