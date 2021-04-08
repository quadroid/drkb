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
body {
  border: 0;
  margin: 0;
  padding: 0;
  color: #eee;
  background: #000;
  font-family: Verdana, "Helvetica Neue", Helvetica, sans-serif;
  font-size: 0.85em;
  overflow: hidden;
}

#container {
  height: 100vh;
  display: flex;
  flex-flow: column;
}

a:link, a:visited, a:hover {
  color: #f93;
}

a.dotted {
  text-decoration: none;
  border-bottom: 1px dotted #f93;
}

ul, li {
  border: 0;
  padding: 0;
  margin: 0;
}

li {
  padding-top: 0.25em;
  padding-bottom: 0.25em;
}

#tree, #results {
  position: relative;
  padding: 0.75em;
  list-style: none;
  white-space: nowrap;
  overflow: scroll;
  flex: 1 1 auto;
}

.tree-item {
  cursor: pointer;
}

li.highlight > .tree-item > span,
li.highlight > div > a {
  background: #f93;
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

#search {
  padding: 0.75em;
  background: #333;
  flex: 0 1 auto;
}

#search .container {
  border: 1px #666 solid;
  border-radius: 4px;
  padding-right: 2em;
  background: #111;
  height: 2em;
}

#search #switch {
  position: relative;
  top: 0;
  right: 0;
  width: 2em;
  height: 2em;
  background: #222;
  float: right;
  margin-right: -2em;
  box-sizing: border-box;
  border-left: 1px #444 solid;
  border-radius: 0 4px 4px 0;
  cursor: pointer;
  color: #999;
  user-select: none;
}

#search #switch.enabled {
  color: #f93;
  background: #333;
}

#search #switch .button {
  width: 2em;
  height: 2em;
  text-align: center;
  vertical-align: middle;
  display: table-cell;
}

#search input {
  border: 0;
  padding: 0.5em;
  width: 100%;
  height: 100%;
  background: none;
  box-sizing: border-box;
  font-family: 'Consolas', 'Monaco', monospace;
  color: #999;
}

input[type=text]:focus {
  outline: none;
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
      t.stopPropagation();
      this.parentNode.parentNode.classList.add("highlight");
    }))
  });

  /* Search */
  const articles = [];
  const tree = document.getElementById("tree");
  const results = document.getElementById("results");
  const searchBar = document.getElementById("search");
  const switchBtn = document.getElementById("switch");
  const items = Array.from(document.getElementsByTagName("li"));
  let lastSelected;

  items.forEach(function(e) {
    const div = e.firstElementChild;
    const a = div.firstElementChild;
    if (a !== null && a.nodeName.toLowerCase() == "a") {
      articles.push ({text: a.innerText, link: a.getAttribute("link"), ref: e});
    } else {
      articles.push ({text: div.innerText, ref: e});
    }
  });

  function showResults() {
    switchBtn.classList.add("enabled");
    results.style.display = "";
    tree.style.display = "none";
  }

  function hideResults() {
    switchBtn.classList.remove("enabled");
    results.style.display = "none";
    tree.style.display = "";
  }

  function unhighlight() {
    Array.from(document.getElementsByClassName("highlight")).forEach((h) => {
      h.classList.remove("highlight");
    });
  }

  function isSeparator (c) {
    if (!c) return true;
    if ("{}[]()<>+-!?@#$%^&*~`:;,._/\\'\"№|".indexOf(c) != -1) return true;
    if (c.charCodeAt(0) <= 32) return true;
    return false;
  }

  function expandItem (node) {
    const getPnode = (node, name) => {
      let pnode = node.parentNode;
      while (pnode && (!pnode.classList || !pnode.classList.contains (name))) {
        pnode = pnode.parentNode;
      }
      return pnode;
    };
    let pnode = getPnode(node, "tree-subitems");
    while (pnode) {
      const pdiv = pnode.previousElementSibling;
      pdiv.classList.remove("collapsed");
      pdiv.classList.add("expanded");
      pnode.style.display = "block";
      pnode = getPnode(pnode, "tree-subitems");
    }
  }

  function search (term) {
    if (term == "") {
      hideResults();
      results.innerHTML = "";
      if (lastSelected) {
        unhighlight();
        expandItem(lastSelected);
        lastSelected.classList.add("highlight");
        lastSelected.scrollIntoView();
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
          res.push({rank: rank, html: "<li><a href='#' link='" + i.link + "'>" + i.text + "</a></li>", ref: i.ref});
        } else {
          res.push({rank: rank, html: "<li><a href='#' class='dotted'>" + i.text + "</a></li>", ref: i.ref});
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
          switchBtn.onclick();
          expandItem(selected);
          selected.classList.add("highlight");
          selected.scrollIntoView();
        }
        t.stopPropagation();
      })
    });

    showResults();
  }

  switchBtn.onclick = (e) => {
    if (tree.style.display === "none") {
      hideResults();
      if (lastSelected) {
        unhighlight();
        expandItem(lastSelected);
        lastSelected.classList.add("highlight");
        lastSelected.scrollIntoView();
        lastSelected = null;
      }
    } else {
      showResults();
    }
  };

  const searchBox = searchBar.querySelector("input");
  searchBox.onchange = (e) => {search(e.target.value.trim())};
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
        <ul id="tree">
          <xsl:apply-templates select="article"/>
        </ul>
        <ul id="results"></ul>
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
