function eat(id)
	if id then
		serveText("Eating cake #%i", id)
	else
		serveText("No cake specified!")
	end
end
