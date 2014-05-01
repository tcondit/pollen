#lang scribble/manual



@title{The story of Pollen}

I created Pollen to overcome limitations & frustrations I repeatedly encountered with existing web-publishing tools. 

If you agree with my characterization of those problems, then you'll probably like the solution that Pollen offers. If not, you probably won't.

@section{Web development and its discontents}

I made my first web page in 1994, shortly after the web was invented. I opened my text editor (at the time, @link["http://www.barebones.com/products/bbedit/"]{BBEdit}), pecked out @code{<html><body>Hello world</body></html>}, then loaded it in @link["http://en.wikipedia.org/wiki/Mosaic_(web_browser)"]{Mosaic}. So did a million other nerds.

If you weren't around then, you didn't miss much. Everything about the web was horrible: the web browsers, the computers running the browsers, the dial-up connections feeding the browsers, and of course HTML itself. At that point, the desktop-software experience was already slick and refined. By comparison, using the web felt like banging rocks together.

That's no longer true. The web is now 20 years old. During that time, most parts of the web have improved dramatically — for instance, the connections are faster, the browsers are more sophisticated, the screens have more pixels. 

But one part has not improved: the way we make web pages. Over the years, tools promising to simplify HTML development have come and mostly gone — from @link["http://www.macobserver.com/reviews/pagemill2.shtml"]{PageMill} to Dreamweaver to @link["http://wordpress.org"]{WordPress} to @link["http://jekyllrb.com"]{Jekyll}. Meanwhile, true web jocks have remained loyal to the original HTML power tool: the humble text editor.

In one way, this makes sense. Web pages are mostly made of text-based data — HTML, CSS, JavaScript, and so on — and the simplest way to mainpulate this data is with a text editor. While HTML and CSS are @link["http://programmers.stackexchange.com/questions/28098/why-does-it-matter-that-html-and-css-are-not-programming-languages"]{not} programming languages, they lend themselves to semantic and logical structure that's most easily expressed by editing them as text. Furthermore, text-based editing makes debugging and performance improvements easier.

But text-based editing is also limited. Though the underlying description of a web page is notionally human-readable, it's largely optimized to be readable by other software — namely, web browsers. HTML markup in particular is verbose and easily mistyped. And isn't it fatally dull to manage all the boilerplate, like surrounding every paragraph with @code{<p>...</p>}? Yes, it is.

For these reasons, much of web development should lend itself to @italic{abstraction} & @italic{automation}. Abstraction means consolidating repetitve, complex patterns into simpler, parameterized forms. Automation means avoiding the manual drudgery of generating the output files. But in practice, tools that enable this abstraction & automation have been slow to arrive, and most have come hobbled with unacceptable deficiencies. 

@section{The better idea: a programming model}

Parallel with my HTML education, I also goofed around with various programming languages — C, C++, Perl, Java, PHP, JavaScript, Python. Unlike HTML, programming languages excel at abstraction and automation. This seemed like the obvious direction for web development to go.

What distinguishes the text-editing model from the programming model? It's a matter of direct vs. indirect manipulation of output. The text-editing model treats HTML as something to be written directly with a text editor. Whereas the programming model treats HTML — or whatever the output is — as the result of compiling a set of source files, which are written in a programming language. The costs of working indirectly via the programming language are offset by the benefits of abstraction & automation.

On the early web, the text-editing model was appealingly precise and quick. On small projects, it worked well enough. But as projects grew, the text-editing model was going to lose steam. I wasn't the only one to notice. Shortly after those million nerds made their first web page by hand, many of them set about devising ways to apply a programming model to web development. 

@section{``Now you have two problems''}

What followed was a steady stream of products, frameworks, tools, and content management systems that claimed to bring a programming model to web development. Some were better than others. But none of them displaced the text editor as the preferred tool of web developers. 

Why not? All these tools promised a great leap forward in solving the web-development problem. In practice, they simply redistributed the pain. I needn't bore you with enumerating the deficiencies of specific tools, because they've tended to fail in the same thematic ways:

@itemlist[

@item{@bold{No native data structure for HTML.} Core to any programming model is data structures. Good data structures make processing easy; bad ones make it hard. Even though HTML has a @link["http://www.w3.org/TR/html401/struct/global.html"]{well documented} format, rarely has it been handled within a programming system with a native, intuitive data structure. Instead, it's either been treated as a string (wrong), a tree (also wrong), or some magical parsed object. This has made working with HTML in programming environments needlessly difficult.}

@item{@bold{Mandatory separation of code, presentation, and content.} This principle has often been @link["http://alistapart.com/article/separationdilemma/"]{held out} as an ideal in web development. But it's also counterintuitive, because an HTML page naturally contains all three. If you want to separate them, your tools should let you. But if you don't, your tools shouldn't make you.}

@item{@bold{Steep learning curves.} Web programmers have often chided designers for not knowing @link["http://elliotjaystocks.com/blog/web-designers-who-cant-code/"]{how to code}. But programming-based web-development tools have often had a high initial learning curve that requires you to throw out your existing workflow. Programmers built these tools — no surprise that programmers have been more comfortable with them.}

]

I've tried a lot of these tools over the years. Some I liked. Some I didn't. Invariably, however, whenever I could still make do with hand-editing an HTML project, I would. After trying to cajole the web framework du jour into doing my bidding, it was relaxing to trade off some efficiency for control.


@section{Rethinking the solution for digital books}

In 2008, I launched a website called @link["http://typographyforlawyers.com"]{@italic{Typography for Lawyers}}. Initially, I'd conceived of it as a book. Then I thought ``no one's going to publish that.'' So it became a website, that I aimed to make as book-like as possible. But hand-editing wasn't going to be enough. 

So I used @link["http://wordpress.org"]{WordPress}. The major chore became scraping out all the crap that typically lives in blog templates. Largely because of this, people liked the site, because it didn't look like the usual blog. Even WordPress developer Matt Mullenweg @link["http://ma.tt/2010/04/typography-for-lawyers/"]{called it} ``a cool use of WordPress for a mini-book.''

Eventually, a publisher offered to release it as a paperback. Later came the inevitable request to make it into a Kindle book. As a fan of typography, I hate the Kindle. The layout controls are coarse, and so is the reading experience. But I didn't run and hide. Basically a Kindle book is a little website made with 1995-era HTML. So I coded up some tools in Perl to convert my book to Kindle format while preserving the formatting and images as well as possible.

At that point, I noticed I had converted @italic{Typography for Lawyers} into web format twice, using two different sets of tools. Before someone asked me to do it a third time, I started thinking about how I might create source code for the book that allowed me to render it into different formats. 

This was the beginning of the Pollen project.

I wrote the initial version of Pollen in Python. I devised a simplified markup-notation language for the source files. This language was compiled into XML-ish data structures using @link["http://www.dabeaz.com/ply/"]{ply} (Python lex/yacc). These structures were parsed into trees using @link["http://lxml.de/"]{LXML}. The trees were combined with templates made in @link["http://chameleon.readthedocs.org/en/latest/"]{Chameleon}. These templates were rendered and previewed with the @link["http://bottlepy.org/"]{Bottle} web server. 

Did it work? Sort of. Source code went in; web pages came out. But it was also complicated and fragile. Moreover, though the automation was there, there wasn't yet enough abstraction at the source layer. I started thinking about how I could add a source preprocessor.

@section{Enter Racket}

I had come across Racket while researching languages suitable for HTML/XML processing. I had unexpectedly learned about the @link["http://www.defmacro.org/ramblings/lisp.html"]{secret kinship} of XML and Lisp: though XML is not a programming language, it uses a variant of Lisp syntax. Thus Lisp languages are particularly adept at handling XMLish structures. That was interesting.

After comparing some of the Lisp & Scheme variants, Racket stood out because it had a text-based dialect called Scribble. Scribble could be used to embed code within textual content. That was interesting too. Among other things, this meant Scribble could be used as a general-purpose preprocessor. So I thought I'd see if I could add it to Pollen.

It worked. So well, in fact, that I started thinking about whether I could reimplement other parts of Pollen in Racket. Then I started thinking about reimplementing all of it in Racket.

So I did. And here we are.

@section{Why Pollen?}

Pollen is a web-development environment built on top of Scribble and Racket. So far I've optimized Pollen for digital books, because that's mainly what I use it for. But it's good for smaller projects too.

Pollen addresses the deficiencies I experienced with other tools:

@itemlist[

@item{@bold{Yes, we have a native data structure for HTML.} Racket represents HTML structures as @italic{X-expressions}, which are a variant of the standard Racket data structure, called @italic{S-expressions}. In other words, not only is there a native representation for HTML, everything in the language is represented this way.}

@item{@bold{Flexible blending of code, presentation, and content.} Pollen is a text-based language. So a Pollen source file might have no code at all. But as a dialect of Scribble & Racket, if you want to mix code with content, you can.}

@item{@bold{Shallow learning curve.} You don't need to do a lot of setup and configuration to start doing useful work with Pollen. Programmers and non-programmers can easily collaborate. Yes, I concede that if you plan to get serious, you'll need to learn some Racket. I don't think you'll regret it.}

]


