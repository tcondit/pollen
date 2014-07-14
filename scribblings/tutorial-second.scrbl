#lang scribble/manual

@(require (for-label racket pollen/world pollen/template pollen/pagetree sugar))

@title[#:tag "second-tutorial"]{Second tutorial}

In this tutorial, you'll use Pollen to publish a multiple-page article written in Markdown. You'll learn about:

@itemlist[

@item{Using Markdown files with the preprocessor}

@item{X-expressions}

@item{Markdown authoring mode}

@item{Templates}

@item{Pagetrees}

]

If you want the shortest possible introduction to Pollen, try the @secref["quick-tour"].

@section[#:tag-prefix "tutorial-2"]{Prerequisites}

I'll assume you've completed the @secref["first-tutorial"] and you understand how to create source files in DrRacket and view them in the project server. I will not be spelling out those tasks as I did before.

@section{Prelude: my principled objection to Markdown}

I recognize that people like Markdown. I want people to like Pollen too, so that's why Markdown support exists in Pollen. But just to be clear about my own views —

I'm mystified by the popularity of Markdown among writers. I can agree that it's a clever and readable way of notating basic HTML. And sure, that makes it great for things like web comments, where speed and simplicity are primary virtues.

In longer-form writing, however, its shortcomings become evident. Like programming languages, the best writing tools maximize expressive possibilities, and minimize constraints. But Markdown is hugely constrained. First and worst, Markdown isn't semantic. It only knows about formatting, and in that regard, isn't that much of an improvement on tools like Microsoft Word. Second, even as a formatting-notation tool, it's limited to a small subset of the already-small set of formatting tags permitted in HTML. Third, it can't be extended by an author.

An animating principle of Pollen, as explained in the @secref["Backstory" #:doc '(lib "pollen/scribblings/pollen.scrbl")], is that after 20 years, we ought to move beyond thinking of HTML as a source format. Since Markdown is just well-disguised HTML, a vote for Markdown is really a vote to continue the status quo (albeit with fewer angle brackets). For me, that's not good enough. I'm ready for the tools to expand to fit my ideas; I don't want to keep cutting down my ideas to fit the tools.

All that said, if you genuinely prefer Markdown, I'm not looking to pry it from your fingers. Pollen has excellent Markdown support (due entirely to Greg Hendershott's excellent @link["https://github.com/greghendershott/markdown/"]{Markdown parser} for Racket). It makes Markdown more useful. 

But let's make a deal, Markdown fans. Having met you more than halfway, will you at least consider that Pollen markup might be a better option for you than Markdown? Because it can notate anything that's in your brain, not just a subset of HTML? And if @secref["The_book_is_a_program" #:doc '(lib "pollen/scribblings/pollen.scrbl")], the source for that book should look more like your brain, and less like HTML?

That's all I ask.


@section{Markdown in Pollen: two options}

There are two ways to use Markdown within Pollen: you can either send Markdown files through the preprocessor, or use Markdown authoring mode. 

The preprocessor approach is better if you want to end up with a set of Markdown files that can be passed along to a HTML converter (or other Markdown-to-______ converter) elsewhere.

The authoring-mode approach is better if you want to end up with something other than Markdown, e.g., finished HTML files.

@subsection{Using Markdown with the preprocessor}

Because Markdown is a text-based format, you can use the Pollen preprocessor to add programmatic features to existing Markdown files. (See @secref["Working_with_the_preprocessor"
         #:doc '(lib "pollen/scribblings/pollen.scrbl")] in the @secref["first-tutorial"] if you need a refresher.)

Suppose we have a Markdown file called @tt{brennan.md} that we want to use with the preprocessor. Create this file in DrRacket, save it, and start the project server in that directory.

@filebox["brennan.md"]{@verbatim{
My name is _Brennan_, and I enjoy:

+ boring sauce

+ 24 fish nuggets}}

You'll be able to see this file in the project server, but for now, it's just a static file. Pollen isn't doing anything to it.

Let's change that. Consistent with the usual preprocessor practice, we add @racketfont{#lang pollen} as the first line, and append the @racketfont{.pp} file extension, so our new preprocessor-ready file looks like this:

@filebox["brennan.md.pp"]{@verbatim{
#lang pollen

My name is _Brennan_, and I enjoy:

+ boring sauce

+ 24 fish nuggets}}

Go back to the project server and you'll see the new filename. When you click on it, Pollen will render a new @racketfont{markdown.md} file, but it will look the same as the one you had before. 

Now we'll change some of the values using Pollen commands:

@filebox["brennan.md.pp"]{@verbatim{
#lang pollen

◊(define sauce-type "fancy")
◊(define nugget-type "chicken")
◊(define nugget-quantity (* 2 2 3))

My name is _Brennan_, and I enjoy:

+ ◊sauce-type sauce

+ ◊nugget-quantity ◊nugget-type nuggets}}

When you reload this file in the project server, @racketfont{brennan.md} will be regenerated, and will now look like this:

@nested[#:style 'code-inset]{@verbatim{
My name is _Brennan_, and I enjoy:

+ fancy sauce

+ 12 chicken nuggets}}



Instead of running Markdown files through the preprocessor, you can also use Markdown authoring mode within Pollen. This is the better choice if you want to end up with rendered HTML files. 

But first, let's pause to clarify the general concept of an authoring mode.


@subsection{Authoring mode}

Though the preprocessor is useful, it limits you to inserting chunks of text at various positions into an existing file.

Pollen's @italic{authoring mode}, by contrast, parses the whole source file into a special data structure called an @italic{X-expression}. You can then process the whole X-expression any way you like, and output to any format you like — or multiple formats — using a @italic{template}.

Compared to the preprocessor, authoring mode offers more abstraction and flexibility. Of course, it's also a bit more effort to set up.

Pollen offers two variants of authoring mode: one that uses Markdown syntax (which we'll cover later in this tutorial) and the other that uses a free-form markup syntax (which we'll cover in the next tutorial). In both cases, the basic idea is the same: parse the source into an X-expression, and then output it using a template.

@subsection{X-expressions}

@margin-note{Don't skip this part! It's not the same old shit. And it describes a concept that's key to how Pollen works.}

I avoid nerdy jargon whenever possible. But in this case, the thing is called an @italic{X-expression} throughout the Racket documentation, for good reasons. So I use the term too. Better to acclimate you now.

An X-expression is a way of representing markup-based data in code. X-expressions are indigenous to Lisp-based languages like Pollen and Racket. They don't exist in Python or JavaScript or Ruby.

Let's start with the part you're familiar with. By ``markup-based data,'' I mean things like HTML and XML and SVG. The idea is that you have text-based data surrounded by @italic{tags}. Each tag can also have its own @italic{attributes} that are made of keys and values. Tags can contain other tags, thus creating a tree-like structure. Right? You know what I mean:

@nested[#:style 'code-inset]{@verbatim{<body><h1>Hello world</h1><p class="first">Nice to <i>see</i> you.</p></body>}}

An X-expression is just a simplified, generalized method of notation for these data structures — much like Markdown is a simplified method of notation for HTML. To see the relationship, we'll convert one into the other. 

First, we change the angle brackets to parentheses, and only use them on the outside of tags:

@nested[#:style 'code-inset]{@verbatim{(body (h1 Hello world /h1) (p class="first" Nice to (i see /i) you. /p) /body)}}

Then we get rid of the closing tags, which are superfluous, since the closing parenthesis marks the end of the tag perfectly well:

@nested[#:style 'code-inset]{@verbatim{(body (h1 Hello world) (p class="first" Nice to (i see) you.))}}

However, this creates ambiguity between the name of the tag and the content. So we'll put the content within quote marks: 

@nested[#:style 'code-inset]{@verbatim{(body (h1 "Hello world") (p class="first" "Nice to" (i "see") "you."))}}

As for the @racketfont{class} attribute, we need to distinguish it from both the markup tags and the content, so we'll move it between double parentheses:

@nested[#:style 'code-inset]{@verbatim{(body (h1 "Hello world") (p ((class "first")) "Nice to" (i "see") "you."))}}

Net of a few boring details, that's basically all there is to it. 

So why is it called an X-expression? Lisp languages are built out of units called S-expressions, which look like this:

@nested[#:style 'code-inset]{@verbatim{(and (txexpr? x) (member (get-tag x) (project-block-tags)) #t))}}

S-expressions use prefix notation, where each pair of parentheses contains a list. The first element in the list names a function, and the other elements are the arguments to that function. (This is a review of @secref["Racket_basics__if_you_re_not_familiar_" #:doc '(lib "pollen/scribblings/pollen.scrbl")].) X-expressions are just a minor adaptation of S-expression notation to represent markup, hence the name (the @italic{X} is short for @italic{XML-like}).

For handling markup-based data, X-expressions have some useful advantages compared to other methods:

@itemlist[

@item{@bold{Readability.} X-expressions retain all the semantics of markup-based data while dispensing with the infamous verbosity.}


@item{@bold{A hybrid between a tree and a string.} Most programming languages represent markup-based data either as a string or as an XML tree. Neither is a good choice. The string captures none of the internal structure of the data. An XML tree captures the structure, but conceals the sequential nature of the data elements. The X-expression gets both.}

@item{@bold{An ideal match for an expression-based programming language.} Aside from some notational details, X-expressions are just a subset of S-expressions generally, which are the building block of Racket. Processing X-expressions in Racket maximizes flexibility and minimizes @link["http://programmers.stackexchange.com/questions/34775/correct-definition-of-the-term-yak-shaving"]{yak-shaving}.}
]

@margin-note{Given the close kinship between XML-ish data structures and Lisp-ish programming languages, I have no explanation why, during the Internet era, they have not been paired more often.}

In Pollen's authoring modes, your source file is parsed into an X-expression, which can then be processed further before being injected into a template & converted to output. As a first example, we'll look at Markdown authoring mode.


@subsection{Markdown authoring mode}

Let's start putting together our article. For simplicity, I'm going to use unrealistically short sample texts. But you can use whatever Markdown content you want.

We want to use Markdown authoring mode to make a file that will ultimately be HTML. So consistent with Pollen file-naming conventions (see @secref["Saving___naming_your_source_file"  #:doc '(lib "pollen/scribblings/pollen.scrbl")]), we'll start with our desired output filename, @racketfont{article.html}, and then append the Markdown authoring suffix, @racketfont{.pmd}. So in DrRacket, start a new file called @racketfont{article.html.pmd} and put some Markdown in it: 

@filebox["article.html.pmd"]{@verbatim{
#lang pollen

Deep Thought
============

I am **so** happy to be writing this.}}

Before you preview this file in the project server, click the @onscreen{Run} button in DrRacket just to see what the file produces. You'll see something like this:

@nested[#:style 'code-inset]{@racketvalfont{'(root (h1 ((id "my-article")) "Deep Thought") (p () "I am " 
@(linebreak)(strong () "so") " happy to be writing this."))}}

You should now be able to recognize this as an X-expression. In authoring mode, Pollen parses your Markdown into the corresponding HTML entities, but then provides the data as an X-expression rather than finished HTML.


@margin-note{The empty parentheses @racketvalfont{()} after @racketvalfont{p} and @racketvalfont{strong} signal that the tag's attributes are empty. When you write an X-expression without attributes, these parentheses are optional — @racketvalfont{(tag () "text")} and @racketvalfont{(tag "text")} are equivalent — but Pollen will always print X-expressions this way.}

From what you learned in the last section, it should be evident that this X-expression corresponds to HTML that looks like this:

@nested[#:style 'code-inset]{@racketvalfont{<root><h1 id="my-article">Deep Thought</h1><p>I am @(linebreak)<strong>so</strong> happy to be writing this.</p></root>}}

``But what's this @racketfont{root} tag? That's not HTML.'' An X-expression must have a root tag, so in the spirit of obviousness, every X-expression produced by a source file in authoring mode will start with @racketfont{root}. If you don't need it, you can discard it. But it also creates a useful hook for further processing, as we'll see later.

By the way, as review, let's remind ourselves how this is different from preprocessor mode. Let's take the same Markdown content, but this time put it into a preprocessor source file called @racketfont{article.md.pp}.

@filebox["article.md.pp"]{@verbatim{
#lang pollen

Deep Thought
============

I am **so** happy to be writing this.}}

When you run this file in DrRacket, you'll see:

@nested[#:style 'code-inset]{@racketvalfont{Deep Thought@(linebreak)============@(linebreak)@(linebreak)I am **so** happy to be writing this.}}

Hopefully, this result makes sense to you: when you run Markdown source in preprocessor mode, you get Markdown. When you run Markdown source in authoring mode, you get an X-expression.

@section[#:tag-prefix "tutorial-2"]{Templates}

So how do you convert an X-expression into a finished file? You use a Pollen @italic{template}, which takes data from an X-expression and converts it to the target format.

If you've used other web-publishing systems, templates are probably a familiar idea. Templates in Pollen are in some ways similar to the ones you've seen before, but in other ways different.

First, the similarities. At its simplest, a template holds boilerplate material that you want to reuse across multiple pages. For instance, in a set of HTML pages, you might have layout and navigation elements that stay the same, while the content changes. In that case, you could put the layout and navigation in the template, and keep the content in your Pollen source files. When you want to add a new page, you can make a new source file and just use it with the existing template. Moreover, if you want to change the layout and navigation globally, you can just change the template, rather than changing the source files.

Pollen templates, like others, can also have conditional features — meaning, you can embed simple code in your templates that allows them to change based on the content in the page. For instance, a template could show or hide ``previous page'' and ``next page'' links depending on whether there's actually a previous or next page.

The major difference with Pollen templates is that there's no special ``template language'' you need to learn, with magic delimiters and whatnot. Instead, you can use all the same Pollen commands in a template that you can in authoring mode or preprocessor mode. 

To see a template in action, let's return to the source file we started in the last section:

@filebox["article.html.pmd"]{@verbatim{
#lang pollen

Deep Thought
============

I am **so** happy to be writing this.}}

Last time, I had you run this file in DrRacket to see the X-expression it produced. This time, load it in the project server. You'll see something like this:

@nested[#:style 'code-inset]{
@bold{@larger{@larger{Deep Thought}}}

I am @bold{so} happy to be writing this.
}

Here, you're seeing the X-expression from your source combined with an HTML template, which adds the necessary boilerplate for the finished HTML:

@nested[#:style 'code-inset]{@racketvalfont{
<html><head><meta charset="UTF-8" /></head><body>
@(linebreak)<root><h1 id="my-article">Deep Thought</h1><p>I am 
@(linebreak)<strong>so</strong> happy to be writing this.</p></root>
@(linebreak)</body></html>}}

But wait — where did the template come from? When you view an authoring-mode source file in the project server without specifying a template, Pollen helps you out and uses its @italic{fallback template}. The fallback template is just a minimal template that's used as a last resort. Under ordinary circumstances, seeing the fallback template usually signals a problem (e.g., Pollen couldn't find the template you asked for).

But we can learn a few things from the fallback template about how to make an HTML template.

@subsection{The @racketfont{->html} function and the @racketfont{doc} variable}

This is the fallback template that Pollen uses.

@filebox["fallback.html"]{@verbatim{◊(->html (html (head (meta 'charset: "UTF-8")) (body doc)))}}

It has three key ingredients. 

First, there's an X-expression that represents a basic HTML page:

@nested[#:style 'code-inset]{@verbatim{(html (head (meta 'charset: "UTF-8")) (body))}}

This is equivalent to the HTML:

@nested[#:style 'code-inset]{@verbatim{<html><head><meta charset="UTF-8"></head><body></body></html>}}

But within a template, we need to explicitly convert from X-expression to HTML. So we wrap this X-expression with our second key ingredient, the Pollen command @racket[->html]:

@nested[#:style 'code-inset]{@verbatim{◊(->html (html (head (meta 'charset: "UTF-8")) (body)))}}

Third, we need to include the content from our source file. We do this by putting the variable @racketfont{doc} inside the @racketfont{body} tag.

@nested[#:style 'code-inset]{@verbatim{◊(->html (html (head (meta 'charset: "UTF-8")) (body doc)))}}

By convention, every Pollen source file makes its output available through the variable @racketfont{doc}. A source file in preprocessor mode puts its text result in @racketfont{doc}. And a source file in authoring mode puts its X-expression result in @racketfont{doc}. 

@margin-note{You can change the name to something other than @racketfont{doc} by changing @racket[world:main-pollen-export].}

Under the hood, a template is just a partial program that relies on a set of variables defined by another source file (fancy name: @italic{lexical context}). So if you ran this template on its own, nothing would happen, because @racketfont{doc} isn't defined. But when you run it in the context of another source file, it picks up the @racketfont{doc} that's defined by that file.

Caution — despite the name, a Pollen template is not necessarily a file of the type suggested by its extension. For instance, @racketfont{fallback.html} is a file that ultimately produces HTML, but it's not actually written in HTML.

It could be, however. Here's an equivalent way of writing @racketfont{fallback.html} that inserts @racketfont{doc} into actual HTML, rather than making the whole thing an X-expression.

 @nested[#:style 'code-inset]{@verbatim{<html><head><meta charset="UTF-8"></head>
<body>◊(->html doc)</body></html>}}

Notice that we still need to use the @racket[->html] function, but this time, instead of surrounding a larger X-expression, it just goes around @racketfont{doc}.

Truly, there is no difference between these two methods. Use whichever works best for you. I often prefer the second method because I like to build & test HTML layouts by hand using placeholder content to make sure all the fiddly bits work. Then it's easy to replace the placeholder content with @racket[(->html doc)], and it becomes a template.


@subsection{Making a custom template}

We'll use these three ingredients to make our own template for @racketfont{article.html.pmd}. 

In general, template files can have any name you want. But by default, Pollen will first look for a file in your project directory called @racketfont{template.ext}, where @racketfont{ext} matches the output-file extension of the source file. So if your source file is @racketfont{database.xml.pmd}, Pollen will look for @racketfont{template.xml}. And for @racketfont{article.html.pmd}, Pollen will look for @racketfont{template.html}.

Therefore, to set up a custom template, all we need to do is create a file called @racketfont{template.html} in our project directory, and make sure it has the three key ingredients we saw in the fallback template. Pollen will automatically apply it to @racketfont{article.html.pmd} when we view it in the project server.

But don't take my word for it. In your project directory, create a new file called @racketfont{template.html}:

@filebox["template.html"]{@verbatim{<html>
<head><meta charset="UTF-8">
<title>Custom template</title></head>
<body>◊(->html doc)</body>
</html>}}

Recall from the last section that this is the same as the fallback template, but written out in HTML, and with a @racketfont{title} element added. In fact, you can now refresh @racketfont{article.html} in the project server. Does it look different? No — it won't, because the resulting template is the same. You should notice, however, that the title of the browser window is now ``Custom template,'' because Pollen is relying on your new template file, rather than the fallback template.

Let's change our custom template by adding a @racketfont{style} block:

@filebox["template.html"]{@verbatim{<html>
<head><meta charset="UTF-8">
<title>Custom template</title>
<style type="text/css">
body {padding: 3em; font-size: 20px;}
h1 {background: gray; color: white;}
strong {color: red;}
</style></head>
<body>◊(->html doc)</body>
</html>}}

When you refresh @racketfont{article.html} in the project server, you'll see that the heading now has a gray background, and one word in the text is red.

Feel free to add other settings to @racketfont{template.html}, or update the text in @racketfont{article.html}, and see how the page changes. As you'd expect, the project server keeps an eye on both your source files and your template files, and if one changes, it will refresh the output file automatically.

@subsection{Inserting specific source data into templates}

In the last example, we used @racketfont{doc} to insert the entire content of the source file — as an X-expression — into the template.

But what if you want to only insert part of your source file into the template? For instance, you'll look like a dork if the title on each page is ``Custom template.'' So let's fix that.

When you're working in a template, Pollen provides a @racket[select] function that lets you extract the content of a specific tag, like so: @racketfont{◊(select '@racketvarfont{tag-name} doc)}, which means ``get the content of @racketvarfont{tag-name} out of @racketfont{doc} and put it here.''

Let's suppose that we'd rather use the name of the article — @italic{Deep Thought} — as the page title. We're going to put a @racketfont{◊(select ...)} command inside the @racketfont{<title>} tag. 

Beyond that, we just need to know the tag name that contains the title. If we have a little Markdown expertise, we might already know that this part of our Markdown source:

@verbatim{Deep Thought
          ============}

is going to produce a tag named @racketfont{h1}. 

What if we don't have all the Markdown conversions memorized? No problem. We can still figure out the tag name by running the @racketfont{article.html.pmd} source file in DrRacket and looking at the X-expression that results:

@nested[#:style 'code-inset]{@racketvalfont{'(root (h1 ((id "my-article")) "Deep Thought") (p () "I am " 
@(linebreak)(strong () "so") " happy to be writing this."))}}

Either way, now we know that the text @italic{Deep Thought} lives in the @racketfont{h1} tag. So we update our template accordingly (for brevity, I'm going to omit the @racketfont{style} tag in these examples, but it's fine to leave it in):

@filebox["template.html"]{@verbatim{<html>
<head><meta charset="UTF-8">
<title>◊(select 'h1 doc)</title></head>
<body>◊(->html doc)</body>
</html>}}

When you refresh the page in the project server, the page title will now appear as ``Deep Thought.'' Of course, you can also combine static and dynamic elements in your template, like so:

@filebox["template.html"]{@verbatim{<html>
<head><meta charset="UTF-8">
<title>◊(select 'h1 doc), by MB</title></head>
<body>◊(->html doc)</body>
</html>}}

The page title will now be ``Deep Thought, by MB''.

A couple notes on command syntax. We inserted the @racket[select] and @racket[->html] commands using Racket-mode syntax. We could also use text-mode syntax and write the commands this way:

@filebox["template.html"]{@verbatim{<html>
<head><meta charset="UTF-8">
<title>◊select['h1 doc], by MB</title></head>
<body>◊->html[doc]</body>
</html>}}

This is exactly equivalent to the previous example. Skeptics are welcome to confirm this by checking the result in the project server.

Finally, notice that in the @racket[select] command, the tag name @racket['h1] is written with a quote mark, whereas @racketfont{doc} is not. This is an easy place to get tripped up, but the rule is simple: you don't use a quote mark when you're referring to the name of an existing function or variable (like @racket[select] or @racketfont{doc}). But you do need a quote mark when you're using the text as a literal value.

@margin-note{Racket (and hence Pollen) makes a distinction between @secref["symbols" #:doc '(lib "scribblings/guide/guide.scrbl")] (e.g. @racket['h1]) and @secref["strings" #:doc '(lib "scribblings/reference/reference.scrbl")] (e.g.  @racket["h1"]). Without getting into the weeds, just note for now that the tag of an X-expression is always a symbol, not a string. But if you write @racketfont{◊(select "h1" doc)}, the command will still work, because Pollen will treat it as @racketfont{◊(select @literal{'}h1 doc)}, consistent with a general policy of not being persnickety about input types when the intention is clear.}


@subsection{Linking to an external CSS file}

If you're a super web hotshot, you probably don't put your CSS selectors in the @racketfont{<head>} tag. Instead, you link to an external CSS file. So it will not surprise you that in Pollen, you can do this by adding the usual @racketfont{<link>} tag to your HTML template, in this case a file called @racketfont{styles.css}:

@filebox["template.html"]{@verbatim{<html>
<head><meta charset="UTF-8">
<title>◊select['h1 doc], by MB</title></head>
<link rel="stylesheet" type="text/css" media="all" href="styles.css" />
<body>◊->html[doc]</body>
</html>}}

Fans of hand-coded CSS, I trust you to take it from here: make your @racketfont{styles.css} file, and enjoy the results.

But folks who paid attention during the @secref["first-tutorial"] might be wondering ``Can we link to a dynamically generated @racketfont{styles.css.pp} file?''

Yes, of course. Here's the rule of thumb: when you're making links between files — whether CSS, or HTML, or anything else — Pollen doesn't care whether the file is static or dynamic. You just refer to it by its ultimate name, in this case @racketfont{styles.css}. If a static @racketfont{styles.css} file exists, Pollen will use that. If it doesn't, Pollen will look for a source file it can use to make @racketfont{styles.css}, and generate it on the spot. (You can also start with a static file, and change it to be dynamic later, and Pollen will do the right thing.)

So to use a dynamic CSS file, we don't need to make any changes to @racketfont{template.html}. We just need to add @racketfont{styles.css.pp} to the project directory:

@filebox["styles.css.pp"]{@verbatim{#lang pollen

◊(define h1-color "blue")
◊(define strong-color "green")

body {padding: 3em; font-size: 20px;}
h1 {background: ◊|h1-color|; color: white;}
strong {color: ◊|strong-color|;}}}

Now, when you refresh @racketfont{article.html} in the project server, Pollen will generate the @racketfont{styles.css} file it needs, and you'll see the new colors in the page. As before, if you update @racketfont{styles.css.pp}, Pollen will notice and regenerate the CSS file when you refresh the page.

Can you add multiple dynamic style sheets? Yes. 
@(linebreak)Can you mix dynamic and static style sheets? Yes.
@(linebreak)Can you add a dynamic JavaScript file? Yes.
@(linebreak)You're getting the general idea, right? So let's move on.

@section[#:tag-prefix "tutorial-2"]{Intermission}

If you only need one page for your article, you can stop here. You now know everything necessary to publish a single-page article using authoring mode. You know how to create the mandatory ingredients — a source file and a template — and  you also know how to link to an optional CSS file, which can be dynamically generated.

If you want to create a multi-page article, however, you need to get through one more big idea. This might be a good time to take a break.

@section[#:tag-prefix "tutorial-2"]{Pagetrees}

A @italic{pagetree} is a hierarchical list of Pollen pages. When you have multiple pages in your project, the pagetree establishes relationships among those pages. At its most basic, a pagetree establishes a linear sequence for the pages. But pagetrees can also establish hierarchical relationships — for instance, a book-length project can be organized into chapters, the chapters into sections, and so on. The pagetree doesn't impose any semantics on the organization of your project. It's just a tree, and it's up to you how many layers to establish, what those layers mean, and so on.

@margin-note{@italic{Pagemap} might've been an equally good name, and perhaps more consistent with similar concepts in other web-publishing systems. But I avoided it out of deference to Racket's @racket[map] function, which means something completely different.}

@subsection{Pagetree navigation}

Pagetrees are used in various ways throughout Pollen. But the most obvious use for a pagetree is to add navigational links to your pages. Obviously, in a multi-page article, readers need a way of getting from one page to the next. In this part of the tutorial, we'll expand our sample article from one page to three, and see how to create ``previous page'' and ``next page'' links in our template that are dynamically generated relative to the current page.


@subsection{Using the automatic pagetree}

You've actually already been exposed to pagetrees (though I didn't tell you about it at the time). Recall that the dashboard of the project server is located at @racketfont{http://localhost:8080/index.ptree}. The list of files you see in the dashboard is a pagetree that Pollen creates by reading the files in the current directory and arranging them in alphabetical order.

If the multiple pages in your project are already ordered by filename, then you can rely on this automatic pagetree. 

From earlier in the tutorial, you have a Markdown source file called @racketfont{article.html.pmd} that looks like this:

@filebox["article.html.pmd"]{@verbatim{
#lang pollen

Deep Thought
============

I am **so** happy to be writing this.}}

Let's supplement this source file by creating two others for the project:

@filebox["barticle.html.pmd"]{@verbatim{
#lang pollen

Barticle Title
==============

The wonderful second part of the article.}}

@filebox["carticle.html.pmd"]{@verbatim{
#lang pollen

Carticle Title
==============

The terrific third part.}}

As before, you can fill these source files with any sample Markdown content you like. Moreover, you don't have to use the filenames @racketfont{barticle.html.pmd} and @racketfont{carticle.html.pmd} — the point is that the intended sequence needs to match the alphabetic sorting of the filenames.

We'll reuse the @racketfont{template.html} and @racketfont{styles.css} files from earlier in the tutorial. Move or delete the other tutorial files so that your dashboard in the project server shows only these five files:

@itemlist[

@item{@racketfont{article.html.pmd}}
@item{@racketfont{barticle.html.pmd}}
@item{@racketfont{carticle.html.pmd}}
@item{@racketfont{styles.css} (or @racketfont{styles.css.pp})}
@item{@racketfont{template.html}}
]

If you click on any of the three Markdown sources, you will see it converted into HTML using @racketfont{template.html}, with styles appiled from @racketfont{styles.css}.

The automatic pagetree for this project is exactly what you see in the dashboard: a list of the three article files, followed by @racketfont{styles.css} and @racketfont{template.html}.

@subsection{Adding navigation links to the template with @racketfont{here}}

Recall from earlier in the tutorial that the content of your source file is made available in the template through the special variable @racketfont{doc}. Likewise, the name of the current source file is made available through the special variable @racketfont{here}. 

To make any navigation link — up, down, sideways — the general idea is that we use @racketfont{here} as input to a pagetree-navigation function, which then looks up the answer in the current pagetree.

First, let's just see @racketfont{here} on its own. Update your template as follows:

@filebox["template.html"]{@verbatim{<html>
<head><meta charset="UTF-8">
<title>◊select['h1 doc], by MB</title></head>
<link rel="stylesheet" type="text/css" media="all" href="styles.css" />
<body>◊->html[doc]
The current page is called ◊|here|.
</body>
</html>}}

If you refresh @racketfont{article.html}, you will now see the line ``The current page is called article.html.'' Switch to @racketfont{barticle.html}, and you'll see ``The current page is called barticle.html.'' Makes sense, right?

Now let's use pagetree functions to show the names of the previous and next pages. Consistent with the usual policy of obviousness, these functions are called @racket[previous] and @racket[next]:

@filebox["template.html"]{@verbatim{<html>
<head><meta charset="UTF-8">
<title>◊select['h1 doc], by MB</title></head>
<link rel="stylesheet" type="text/css" media="all" href="styles.css" />
<body>◊->html[doc]
The current page is called ◊|here|.
The previous is ◊|(previous here)|. 
The next is ◊|(next here)|.
</body>
</html>}}

Refresh @racketfont{barticle.html}. You'll now see that ``The current page is called barticle.html. The previous is article.html. The next is carticle.html.'' So far, so good: we're correctly deriving the previous and next pages from the automatic pagetree.

All that's left is to add hyperlinks, which is easy:

@filebox["template.html"]{@verbatim{<html>
<head><meta charset="UTF-8">
<title>◊select['h1 doc], by MB</title></head>
<link rel="stylesheet" type="text/css" media="all" href="styles.css" />
<body>◊->html[doc]
The current page is called ◊|here|.
The previous is <a href="◊|(previous here)|">◊|(previous here)|</a>. 
The next is <a href="◊|(next here)|">◊|(next here)|</a>.
</body>
</html>}}

Refresh @racketfont{barticle.html}, and you'll see that the names of the previous and next pages are now hyperlinks to those pages. Click through and convince yourself that it works.

@margin-note{The documentation for pagetree @secref["Navigation" #:doc '(lib "pollen/scribblings/pollen.scrbl")] will tell you about the other functions available for generating navigation links.}

@subsection{Handling navigation boundaries with conditionals}

If you clicked through to @racketfont{article.html} or @racketfont{carticle.html}, you might've noticed a couple problems. Because @racketfont{article.html} is the first page in the automatic pagetree, it doesn't have any previous page it can link to. And the next-page link for @racketfont{carticle.html} is @racketfont{styles.css}, which is strictly correct — it is, in fact, the next file in the automatic pagetree — but it's not part of our article, so we'd rather stop the navigation there.

One way to fix the problem would be to have three separate template files — the standard one with both previous- and next-page links, one with only a next-page link, and one with only a previous-page link. 

But since we have a whole programming language available in Pollen, that's a dull-witted way to solve the problem. The better way is to add @italic{conditionals} to the template to selectively change the navigation. That keeps things simple, because we'll still have only one @racketfont{template.html} to deal with.

To handle @racketfont{article.html}, we want to hide the previous-page navigation link when there's no previous page. As it turns out, if the @racket[previous] function can't find a previous page, it will return false. So we just need to wrap our previous-page navigation in the @racket[when/block] command like so:

@filebox["template.html"]{@verbatim{<html>
<head><meta charset="UTF-8">
<title>◊select['h1 doc], by MB</title></head>
<link rel="stylesheet" type="text/css" media="all" href="styles.css" />
<body>◊->html[doc]
The current page is called ◊|here|.
◊when/block[(previous here)]{The previous is <a href="◊|(previous here)|">◊|(previous here)|</a>.} 
The next is <a href="◊|(next here)|">◊|(next here)|</a>.
</body>
</html>}}

The basic structure of @racket[when/block] is @racketfont{◊when/block[@racketvarfont{condition}]{@racketvarfont{insert-this-text}}.} Note the square braces around the @racketvarfont{condition}, and the curly braces around the @racketvarfont{text}. Using @racketfont{(previous here)} as the condition is shorthand for ``when @racketfont{(previous here)} does not return false...''

Programmers in the audience might be getting anxious about the repeated use of @racketfont{(previous here)} — you're welcome to store that value in a variable, and everything will work the same way:

@filebox["template.html"]{@verbatim{<html>
<head><meta charset="UTF-8">
<title>◊select['h1 doc], by MB</title></head>
<link rel="stylesheet" type="text/css" media="all" href="styles.css" />
<body>◊->html[doc]
The current page is called ◊|here|.
◊(define prev-page (previous here))
◊when/block[prev-page]{The previous is <a href="◊|prev-page|">◊|prev-page|</a>.} 
The next is <a href="◊|(next here)|">◊|(next here)|</a>.
</body>
</html>}}

We need a different technique for handling the end of the next-page navigation, because we're not reaching the actual end of the pagetree. We're just reaching the end of the pages we care about navigating through. 

What condition will help us detect this? Here, we can notice that the names of our article pages all contain the string @racketfont{article}. While you'd probably want a more robust condition for a real project, in this tutorial, what we'll do is hide the next-page navigation if the name of the next page doesn't contain ``@racketfont{article}''. As we did before, we wrap our navigation line in the @racket[when/block] function:

@filebox["template.html"]{@verbatim{<html>
<head><meta charset="UTF-8">
<title>◊select['h1 doc], by MB</title></head>
<link rel="stylesheet" type="text/css" media="all" href="styles.css" />
<body>◊->html[doc]
The current page is called ◊|here|.
◊(define prev-page (previous here))
◊when/block[prev-page]{The previous is <a href="◊|prev-page|">◊|prev-page|</a>.} 
◊when/block[(regexp-match "article" (->string (next here)))]{
The next is <a href="◊|(next here)|">◊|(next here)|</a>.}
</body>
</html>}}

This time, the condition is @racket[(regexp-match "article" (->string (next here)))]. How were you supposed to know this? You weren't. That's why this is a tutorial. Without going on a lengthy detour, the @racket[regexp-match] function returns true if the first string (in this case, @racket["article"]) is found inside the second string (in this case, we convert @racket[(next here)] to a string by wrapping it in @racket[->string]).

In any case, even if some of the programmy bits went over your head just now, relax and paste the code into your template. What you'll see when you refresh @racketfont{carticle.html} is that the next-page link is gone. So now our template lets us navigate among the pages of our article, and the conditionals handle the end pages correctly.

@subsection{Making a pagetree file}

I didn't want to dwell on programming complications in the last conditional. Why? The extra programming was necessary only because we made life somewhat difficult for ourselves by relying on the automatic pagetree. A better way to solve the problem is to avoid it altogether by making a pagetree file.

Pagetree source files have a different syntax and status than other Pollen source files, so they are parsed using their own Pollen dialect. To invoke this dialect, you just start the file with @racketfont{#lang pollen} and name the file with the @racketfont{ptree} extension, for instance @racketfont{my-project.ptree}. While you can have as many pagetrees in your project as you want, Pollen will accord primary status to the one named @racketfont{index.ptree}.

So let's make an @racketfont{index.ptree} file. At its simplest, a pagetree file can just be a list of files in the intended order. In DrRacket, create a new file in your project directory as follows:

@filebox["index.ptree"]{@verbatim{
#lang pollen

carticle.html
article.html
barticle.html
}}

Now run the file. The result will be:

@nested[#:style 'code-inset]{@racketvalfont{'(pagetree-root carticle.html article.html barticle.html)}}

Pretty boring, I know. But behind the scenes, Pollen's pagetree parser is making sure your tree is valid (e.g., no duplicate or malformed names). Today it's boring, but on the day you have a long and complicated pagetree, you will be grateful.

Notice that the names in this pagetree are the names of @italic{output} files, not source files. This is deliberate, so that neither you nor Pollen has to care which files are static vs. dynamic. This next pagetree wouldn't be wrong in the sense of bad syntax — the pagetree parser won't complain — but it would be wrong in the sense of not-what-you-want, because it refers to source names rather than output names:

@filebox["bad-index.ptree"]{@verbatim{
#lang pollen

carticle.html.pmd
article.html.pmd
barticle.html.pmd
}}

You also probably noticed that the files are in a different order than they were in the automatic pagetree: @racketfont{carticle.html} is first, followed by @racketfont{article.html} and then @racketfont{barticle.html}. This too is deliberate, so we can see what happens with a differently ordered pagetree.

Pagetrees don't change nearly as often as other source files, so as a performance optimization, the project server does @italic{not} dynamically reflect changes to pagetrees. To see the effect of this new pagetree on our project, you'll need to go to your terminal window and stop the project server with ctrl+C, and then restart it. Which will take all of three seconds.

Now refresh @racketfont{carticle.html}. You'll notice that the navigation links are different. You won't see a previous-page link — because @racketfont{carticle.html} is now the first page in the pagetree — and the next page will show up as @racketfont{article.html}. Click through to @racketfont{article.html}, and you'll see the navigation likewise updated. Click through to @racketfont{barticle.html}, and you'll see ...

BAM! An error page with a yellow box that says @racketfont{Can’t convert #f to string}. What happened? We switched to using our own pagetree file but we didn't update our template conditionals. Once you reach @racketfont{barticle.html}, the value of @racket[(next here)] is false, which means the @racket[(->string (next here))] command in the template conditional is trying to convert false into a string. Hence the error.

 So let's go back and fix that. Because we don't have extraneous files in our pagetree anymore, we can change the second conditional in the template to work the same way as the first:

@filebox["template.html"]{@verbatim{<html>
<head><meta charset="UTF-8">
<title>◊select['h1 doc], by MB</title></head>
<link rel="stylesheet" type="text/css" media="all" href="styles.css" />
<body>◊->html[doc]
The current page is called ◊|here|.
◊(define prev-page (previous here))
◊when/block[prev-page]{The previous is <a href="◊|prev-page|">◊|prev-page|</a>.} 
◊(define next-page (next here))
◊when/block[next-page]{
The next is <a href="◊|next-page|">◊|next-page|</a>.}
</body>
</html>}}

Refresh @racketfont{barticle.html} — because you're updating the template, you don't need to restart the project server — and you'll see the right result. The previous-page link goes to @racketfont{article.html}, and the next-page link is hidden.

@subsection{@racketfont{index.ptree} & the project server}

One more thing to show you before we wrap up this tutorial. Remember that the dashboard of the project server is at @racketfont{http://localhost:8080/index.ptree}? By default, the project server will synthesize a pagetree from an alphbetical directory listing. 

But if you put your own @racketfont{index.ptree} file in the directory, the project server will use that for the dashboard instead. In fact, visit @racketfont{http://localhost:8080/index.ptree} now and you'll see what I mean. Consistent with the @racketfont{index.ptree} you made, you'll now see @racketfont{carticle.html}, @racketfont{article.html}, and @racketfont{barticle.html}, but not @racketfont{template.html} nor @racketfont{styles.css} (even though they're still in the project directory).


@section{Second tutorial complete}

That was a big tutorial. I commend you for your tenacity and patience. But in this tutorial, you made a giant leap forward. Despite the silly examples, you now know everything you need to make multi-page articles — books, even — using Markdown authoring mode in Pollen. If this is all you ever use Pollen for, it'll be a big improvement over ordinary Markdown.

But there's more. We haven't even gotten into the more elaborate automation that's possible with Pollen, nor Pollen's own markup language. We'll cover that in the third tutorial.


