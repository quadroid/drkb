<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" indent="no"/>

  <xsl:template name="string-replace-all">
    <xsl:param name="text"/>
    <xsl:param name="replace"/>
    <xsl:param name="by"/>
    <xsl:choose>
      <xsl:when test="contains($text,$replace)">
        <xsl:value-of select="substring-before($text,$replace)"/>
        <xsl:value-of select="$by"/>
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="substring-after($text,$replace)"/>
          <xsl:with-param name="replace" select="$replace"/>
          <xsl:with-param name="by" select="$by"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="/drkb">
    <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
    <html><head>
<style><xsl:text disable-output-escaping="yes"><![CDATA[
* {
  box-sizing: border-box;
}

html, body {
  border: 0;
  margin: 0;
  padding: 0;
  height: 100vh;
}

body {
  color: #eee;
  background: #111;
  font-family: Verdana, "Helvetica Neue", Helvetica, Arial, sans-serif;
  font-size: 0.85em;
  overflow: hidden;
}

/* Stretch to fill vertical column space */
#container {
  position: relative;
  height: 100%;
  display: flex;
  flex-flow: column;
}

/* Links */
a:link, a:visited, a:hover {
  color: #fb3;
}

a.dotted {
  text-decoration: none;
  border-bottom: 1px dotted #f93;
}

/* Articles tree */
ul, li {
  border: 0;
  padding: 0;
  margin: 0;
}

li {
  padding-top: 0.25em;
  padding-bottom: 0.25em;
}

#container > .container {
  overflow: scroll;
  overflow-x: hidden;
  flex: 1;
}

#tree, #results {
  position: relative;
  padding: 0.75em;
  list-style: none;
  white-space: nowrap;
  user-select: none;
}

.tree-item {
  cursor: pointer;
}

li.highlight > .tree-item > span,
li.highlight > div > a {
  background: #fb3;
  border-radius: 4px;
  padding: 0.25em;
  color: #000;
}

ul.tree-subitems {
  list-style: none;
  padding-left: 1em;
}

div.tree-item.collapsed:before {
  content: "▸";
  width: 1em;
  display: inline-block;
}

div.tree-item.expanded:before {
  content: "▾";
  width: 1em;
  display: inline-block;
}

/* Search box */
#search {
  padding: 0.75em;
  background: #333;
  flex: 0;
}

#search .container {
  border: 1px #666 solid;
  border-radius: 4px;
  padding-right: 2em;
  background: #111;
  height: 2em;
  box-sizing: content-box;
}

#search #switch {
  position: relative;
  top: 0;
  right: 0;
  width: 2em;
  height: 2em;
  float: right;
  color: #999;
  background: #333;
  font-weight: bold;
  text-align: center;
  margin-right: -2em;
  box-sizing: border-box;
  border-left: 1px #666 solid;
  border-radius: 0 4px 4px 0;
  cursor: pointer;
  user-select: none;
}

#search #switch.enabled {
  color: #f93;
  background: #444;
}

#search #switch .button {
  width: 2em;
  height: 2em;
  text-align: center;
  vertical-align: middle;
  display: table-cell;
}

#search input {
  font-family: Consolas, Menlo, Monaco, "Courier New", Courier, monospace;
  border: 0;
  padding: 0.5em;
  width: 100%;
  height: 100%;
  background: none;
  box-sizing: border-box;
  color: #999;
}

/* Hide outline glow */
input[type=text]:focus {
  outline: none;
}

/* Customize scrollbars (WebKit) */
::-webkit-scrollbar {
  width: .5em;
}

::-webkit-scrollbar-track {
  background: #111;
}

::-webkit-scrollbar-thumb {
  background: #f93;
}

::-webkit-scrollbar-thumb:hover {
  background: #c60;
}

/* Customize scrollbars (Firefox) */
body {
  scrollbar-color: #f93 #111;
  scrollbar-width: thin;
}

/* Progress animation */
#progress {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 1;
  display: none;
}

#progress > .container {
  position: absolute;
  top: 50%;
  left: 50%;
  margin-top: 1.75em;
}

#progress span {
  position: absolute;
  top: -1vh;
  width: 2vw;
  height: 2vh;
  background: #f93;
}

#progress span:nth-of-type(1) {
  left: -5vw;
  animation: bloat 600ms ease infinite;
  animation-delay: -600ms;
}

#progress span:nth-of-type(2) {
  left: -1vw;
  animation: bloat 600ms ease infinite;
  animation-delay: -450ms;
}

#progress span:nth-of-type(3) {
  left: 3vw;
  animation: bloat 600ms ease infinite;
  animation-delay: -300ms;
}

@keyframes bloat {
  0% {
    top: -1vh;
    height: 2vh;
  }
  50% {
    top: -2vh;
    height: 4vh;
  }
  100% {
    top: -1vh;
    height: 2vh;
  }
}
]]></xsl:text></style>
<script><xsl:text disable-output-escaping="yes"><![CDATA[
"use strict"

function main() {
  /* Collapse entire tree */
  const treeItems = document.getElementsByClassName("tree-item");

  Array.from(treeItems).forEach(function(e) {
    const n = e.nextElementSibling;
    e.classList.add("collapsed");
    n.style.display = "none";
    e.addEventListener("click", function(t) {
      t.preventDefault();
      let e = t.target;
      if (e.nodeName.toLowerCase() != "div") {
        e = e.parentNode;
      }
      const n = e.nextElementSibling;
      if (n.style.display == "none") {
        e.classList.remove("collapsed");
        e.classList.add("expanded");
        n.style.display = "block";
      } else {
        e.classList.remove("expanded");
        e.classList.add("collapsed");
        n.style.display = "none";
      }
      t.stopPropagation();
    });
  });

  /* Enable links */
  const links = document.getElementsByTagName("a");

  Array.from(links).forEach(function(e) {
    e.addEventListener("click", (function(t) {
      t.preventDefault();
      unhighlight();
      window.top.postMessage({
        msg: 'article',
        title: this.innerText,
        link: this.getAttribute("link")
      }, '*');
      /* Bubble up so that clicking on a link also expands
      // or collapses its tree node */
      //t.stopPropagation();
      this.parentNode.parentNode.classList.add("highlight");
    }))
  });

  /* Search */
  const articles = [];
  const tree = document.getElementById("tree");
  const results = document.getElementById("results");
  const searchBar = document.getElementById("search");
  const searchBox = searchBar.querySelector("input");
  const switchBtn = document.getElementById("switch");
  const progress = document.getElementById("progress");
  const items = Array.from(document.getElementsByTagName("li"));
  const container = tree.parentNode;
  const searchDelay = 2000;
  let searchTimeout = 0;
  let lastTerm = "";
  let lastSelected;
  let currView;

  function scrollIntoView(e, c) {
    /* A weird bug occurs where entire page moves slightly
    // off-screen (to the top), producing ugly white strip at
    // the bottom of the browser view, when using `scrollIntoView()`.
    // Weird browser bugs: probably because we are using `<iframe>`s.
    // Firefox and Safari exhibit the bug, other WebKit
    // browsers appear to be fine. */
    if (true) {
      /* There appear to be two solutions: one is to set the scroll
      // offset directly... */
      c.scrollTop = e.offsetTop;
    } else {
      /* ...another is just to scroll the whole body
      // after scrolling the element */
      e.scrollIntoView();
      document.body.scrollIntoView();
    }
  }

  /* Collect article nodes */
  items.forEach(function(e) {
    const div = e.firstElementChild;
    const a = div.firstElementChild;
    if (a !== null && a.nodeName.toLowerCase() == "a") {
      articles.push ({text: a.innerText, link: a.getAttribute("link"), ref: e});
    } else {
      articles.push ({text: div.innerText, ref: e});
    }
  });

  /* Toggle search progress & results */
  function showProgress() {
    currView.style.opacity = .5;
    progress.style.display = "block";
  }

  function hideProgress() {
    currView.style.opacity = '';
    progress.style.display = "none";
  } 

  function showResults() {
    switchBtn.classList.add("enabled");
    results.style.display = "";
    tree.style.display = "none";
    currView = results;
  }

  function hideResults() {
    switchBtn.classList.remove("enabled");
    results.style.display = "none";
    tree.style.display = "";
    currView = tree;
  }

  /* Search routines */
  function unhighlight() {
    Array.from(document.getElementsByClassName("highlight")).forEach((h) => {
      h.classList.remove("highlight");
    });
  }

  /* Input element is a `<li>` tag */
  function expandToItem (node) {
    let pnode;
    const getPnode = (node, name) => {
      let pnode = node.parentNode;
      while (pnode && (!pnode.classList || !pnode.classList.contains(name))) {
        pnode = pnode.parentNode;
      }
      return pnode;
    };
    if (node.firstChild.classList.contains("tree-item")) {
      pnode = node.firstChild.nextElementSibling;
    }
    else pnode = getPnode(node, "tree-subitems");
    while (pnode) {
      const pdiv = pnode.previousElementSibling;
      pdiv.classList.remove("collapsed");
      pdiv.classList.add("expanded");
      pnode.style.display = "block";
      pnode = getPnode(pnode, "tree-subitems");
    }
  }

  function isSeparator (c) {
    if (!c) return true;
    if ("{}[]()<>+-!?@#$%^&*~`:;,._/\\'\"№|".indexOf(c) != -1) return true;
    if (c.charCodeAt(0) <= 32) return true;
    return false;
  }

  function search (term) {
    if (term === lastTerm) return;
    lastTerm = term;

    if (term == "") {
      hideResults();
      results.innerHTML = "";
      if (lastSelected) {
        unhighlight();
        expandToItem(lastSelected);
        lastSelected.classList.add("highlight");
        scrollIntoView(lastSelected, container);
        lastSelected = null;
      }
      return;
    }

    const res = [];
    const terms = term.toLocaleLowerCase().split (' ');
    results.innerHTML = "";

    articles.forEach((i) => {
      let rank = 0;
      const text = i.text.toLocaleLowerCase();
      terms.forEach ((t) => {
        let i;
        if ((i = text.indexOf (t)) !== -1) {
          ++rank;
          if (isSeparator(text[i - 1])) ++rank;
          if (isSeparator(text[i + t.length])) ++rank;
        }
      });
      if (rank !== 0) {
        if (i.link) {
          res.push({rank: rank, html: "<li><a href='#' link='" + i.link + "'>"
          + i.text + "</a></li>", ref: i.ref});
        } else {
          res.push({rank: rank, html: "<li><a href='#' class='dotted'>"
          + i.text + "</a></li>", ref: i.ref});
        }
      }
    });

    res.sort ((e1, e2) => {return (e1.rank < e2.rank) - (e1.rank > e2.rank)});
    res.forEach ((r) => {
      results.insertAdjacentHTML("beforeend", r.html);
      if (r.ref) {
        const last = results.lastElementChild;
        last.ref = r.ref; // remember reference in DOM
      }
    });

    Array.from(results.querySelectorAll("a")).forEach((e) => {
      e.addEventListener("click", function(t) {
        t.preventDefault();
        const selected = this.parentNode.ref;
        const link = this.getAttribute("link");
        if (link) {
          lastSelected = selected;
          window.top.postMessage({
            msg: 'article',
            title: this.innerText,
            link: link
          }, '*');
        } else {
          unhighlight();
          lastSelected = null;
          switchViews();
          expandToItem(selected);
          //selected.classList.add("highlight");
          scrollIntoView(selected, container);
        }
        t.stopPropagation();
      })
    });

    showResults();
  }

  /* Switch between article tree and search results */
  function switchViews(e) {
    if (tree.style.display === "none") {
      hideResults();
      if (lastSelected) {
        unhighlight();
        expandToItem(lastSelected);
        lastSelected.classList.add("highlight");
        scrollIntoView(lastSelected, container);
        lastSelected = null;
      }
    } else {
      showResults();
    }
  }

  switchBtn.addEventListener("click", switchViews);

  /* Begin automatic search countdown */
  function beginSearch (key) {
    if (!searchTimeout) {
      if (lastTerm === searchBox.value.trim()) return;
      showProgress();
    } else clearTimeout(searchTimeout);
    searchTimeout = setTimeout(() => {
      doSearch(searchBox);
    }, searchDelay);
  }

  function searchKey (e) {
    if (e.altKey || e.ctrlKey || e.shiftKey || e.metaKey
    ||  e.keyCode === 13) return;
    beginSearch();
  }

  searchBox.addEventListener("keydown", searchKey);
  searchBox.addEventListener("keyup", searchKey);

  /* Search instantly on enter or lost focus */
  function doSearch (box) {
    hideProgress();
    clearTimeout(searchTimeout);
    searchTimeout = 0;
    search(box.value.trim());
  }

  searchBox.addEventListener("change", (e) => {
    doSearch(e.target);
  });

  searchBox.value = "";
  hideResults();
}

document.addEventListener("DOMContentLoaded", (e) => {main()});
]]></xsl:text></script>
    </head>
    <body>
      <div id="container">
        <div id="search">
          <div class="container">
            <input type="text" placeholder="Search"/>
            <span id="switch"><span class="button">···</span></span>
          </div>
        </div>
        <div class="container">
          <div id="progress">
            <div class="container">
              <span></span><span></span><span></span>
            </div>
          </div>
          <ul id="tree">
            <xsl:apply-templates select="article"/>
          </ul>
          <ul id="results"></ul>
        </div>
      </div>
    </body>
    </html>
  </xsl:template>

  <xsl:template match="article">
    <xsl:variable name="page">
      <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text" select="@page"/>
        <xsl:with-param name="replace" select="'\'"/>
        <xsl:with-param name="by" select="'/'"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:if test="not(starts-with($page,'help/'))">
      <li>
        <div>
          <xsl:if test="count(article)">
            <xsl:attribute name="class">
              <xsl:value-of select="'tree-item'"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:choose>
            <xsl:when test="$page != ''">
              <a href="#">
                <xsl:attribute name="link">
                  <xsl:value-of select="$page"/>
                </xsl:attribute>
                <xsl:value-of select="@name"/>
              </a>
            </xsl:when>
            <xsl:otherwise>
              <span><xsl:value-of select="@name"/></span>
            </xsl:otherwise>
          </xsl:choose>
        </div>
        <xsl:if test="count(article)">
          <ul class="tree-subitems">
            <xsl:apply-templates select="article"/>
          </ul>
        </xsl:if>
      </li>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
