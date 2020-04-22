// Email.js version 5
var tld_ = new Array()
tld_[0] = "a.b";
tld_[1] = "victorchang";
tld_[2] = "edu";
tld_[3] = "au";
tld_[4] = "info";
tld_[10] = "co.uk";
tld_[11] = "org.uk";
tld_[12] = "gov.uk";
tld_[13] = "ac.uk";
var topDom_ = 13;
var m_ = "mailto:";
var a_ = "@";
var d_ = ".";

function mail(name, dom, tl,  display)
{
        document.write('<a href="'+m_+e(name,tl)+'">'+'<img src="'+dom+'">'+'</a>');
}
function e(name, tl)
{
	var s = name+a_;
	if (tl>0)
	{
                var i=1;
		while (i<=tl)
			s+= d_+tld_[i++];
	}
	else
		s+= "badexample.com";
	return s;
}
