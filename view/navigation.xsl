<!-- This stylesheet is concerned with rendering the navigational
     components of the site (menus, breadcrumbs, etc.)
-->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:u    ="http://marklogic.com/rundmc/util"
  xmlns:ml   ="http://developer.marklogic.com/site/internal"
  xmlns:srv  ="http://marklogic.com/rundmc/server-urls"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp srv">

  <xsl:import href="pre-process-navigation.xsl"/>


  <!-- The page occurs in the hierarchy either explicitly or as encompassed by a wildcard.

       If the exact URI is found, then use that;
       otherwise, look to see if the current page falls under a content-type wildcard.

       If the URI is found more than once (as may happen with blog posts), only the first one is chosen.
  -->
  <xsl:variable name="page-in-navigation" select="($navigation//*    [@pref eq '1'][@href eq $external-uri],
                                                   $navigation//*            [@href eq $external-uri],
                                                   $navigation//Article      [$content/Article/@type eq @type],
                                                   $navigation//Announcement [$content/Announcement],
                                                   $navigation//Event        [$content/Event]
                                                  )[1]"/>

  <!-- Home page link always points to main server (even from API server) -->
  <xsl:template match="xhtml:a/@ml:href[. eq '/']">
    <xsl:attribute name="href">
      <xsl:value-of select="$srv:main-server"/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="top-nav">
    <nav>
      <ul>
        <xsl:apply-templates mode="top-nav" select="$navigation/*/page[not(@hide eq 'yes')]"/>
      </ul>
    </nav>
  </xsl:template>

          <xsl:template mode="top-nav" match="page">
            <li>
              <xsl:apply-templates mode="top-nav-current-att" select="."/>
              <xsl:variable name="server-prefix" select="if (starts-with(@href,'/')) then if (@api-server)
                                                                                     then $srv:api-server
                                                                                     else $srv:main-server
                                                         else ()"/>
              <a href="{$server-prefix}{@href}">
                <xsl:variable name="short-description"
                              select="document(concat(@href, '.xml'))//ml:short-description"/>
                <xsl:if test="$short-description">
                    <xsl:attribute name="class">stip</xsl:attribute>
                    <xsl:attribute name="title">
                        <xsl:value-of select="$short-description"/>
                    </xsl:attribute>
                </xsl:if>
                <xsl:apply-templates mode="nav-text" select="@display"/>
              </a>
            </li>
          </xsl:template>

                  <xsl:template mode="top-nav-current-att" match="page"/>

                  <xsl:template mode="top-nav-current-att" match="page[descendant-or-self::* intersect $page-in-navigation]
                                                                | page[@api-server and $currently-on-api-server]
                                                                | page[@starts-with and starts-with($external-uri, @starts-with)]">
                    <xsl:attribute name="class">current</xsl:attribute>
                  </xsl:template>

                          <!-- overridden in apidoc/view/page.xsl -->
                          <xsl:variable name="currently-on-api-server" select="false()"/>


  <xsl:template mode="nav-text" match="@display">
    <xsl:analyze-string select="." regex="&#174;">
      <xsl:matching-substring>
        <sup>
          <xsl:value-of select="."/>
        </sup>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:value-of select="."/>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>

  <xsl:template match="doc-breadcrumbs"/>
  <!-- Only display this for Learn docs -->
  <xsl:template match="doc-breadcrumbs[$content/Article]">
    <div id="content_title">
      <xsl:call-template name="breadcrumbs"/>
    </div>
  </xsl:template>

  <!-- For Learn content, breadcrumbs are handled elsewhere -->
  <xsl:template match="breadcrumbs[$content/Article]"/>

  <xsl:template match="breadcrumbs" name="breadcrumbs">
    <xsl:apply-templates mode="breadcrumbs" select="$page-in-navigation[1]"/>
  </xsl:template>

          <!-- No breadcrumbs on home page -->
          <xsl:template mode="breadcrumbs" match="page[@href eq '/']"/>

          <!-- But do display them on every other page -->
          <xsl:template mode="breadcrumbs" match="*" name="breadcrumbs-impl">
            <xsl:param name="site-name" select="'Developer Community'"/>
            <div>
              <a href="/">
                <xsl:value-of select="$site-name"/>
              </a>
              <xsl:apply-templates mode="breadcrumb-link" select="ancestor::page"/>
              <xsl:apply-templates mode="breadcrumb-display" select="."/>
            </div>
          </xsl:template>

                  <xsl:template mode="breadcrumb-display" match="page | generic-page">
                    <xsl:text> > </xsl:text>
                    <xsl:apply-templates mode="nav-text" select="@display"/>
                  </xsl:template>

                  <xsl:template mode="breadcrumb-display" match="*">
                    <xsl:text> > </xsl:text>
                    <xsl:value-of select="$content/*/title"/>
                  </xsl:template>


                  <xsl:template mode="breadcrumb-link" match="page">
                    <xsl:text> > </xsl:text>
                    <a href="{@href}">
                      <xsl:apply-templates mode="nav-text" select="@display"/>
                    </a>
                  </xsl:template>

  <xsl:template match="sub-nav[$content/Article]">
    <xsl:if test="$content/Article//xhtml:h3">
        <h2>Contents</h2>
        <ul>
            <xsl:apply-templates mode="article-toc" select="$content/Article//xhtml:h3"/>
        </ul>
    </xsl:if>
  </xsl:template>

          <xsl:template mode="article-toc" match="xhtml:h3">
            <li>
              <span>
              <a href="#{generate-id(.)}">
                <xsl:value-of select="."/>
              </a>
              </span>
            </li>
          </xsl:template>

          <xsl:template match="xhtml:h3" priority="1">
            <xsl:param name="annotate-headings" tunnel="yes" select="false()"/>
            <xsl:choose>
              <xsl:when test="$annotate-headings">
                <h3>
                  <xsl:apply-templates select="@*"/>
                  <a name="{generate-id(.)}"/>
                  <xsl:apply-templates/>
                </h3>
              </xsl:when>
              <xsl:otherwise>
                <xsl:next-match/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:template>


  <xsl:template match="sub-nav">
    <xsl:variable name="sub-nav-root" select="$page-in-navigation/ancestor-or-self::page[group | page]"/>
    <xsl:variable name="children" select="$sub-nav-root/(group | page)"/>
    <xsl:if test="$children">
      <div class="subnav {if ($sub-nav-root/@closed eq 'yes') then 'closed' else ''}">
        <xsl:choose>
          <xsl:when test="$children/self::group">
            <xsl:apply-templates mode="sub-nav" select="$children"/>
          </xsl:when>
          <!-- Otherwise, they're not grouped; they're just pages in one list -->
          <xsl:otherwise>
            <ul>
              <xsl:apply-templates mode="sub-nav" select="$children"/>
            </ul>
          </xsl:otherwise>
        </xsl:choose>
      </div>
    </xsl:if>
  </xsl:template>

          <xsl:template mode="sub-nav" match="group">
            <h2>
              <xsl:apply-templates mode="nav-text" select="@display"/>
            </h2>
            <ul>
              <xsl:apply-templates mode="sub-nav" select="page | group"/>
            </ul>
          </xsl:template>

                  <xsl:template mode="sub-nav" match="group/group">
                    <li>
                      <xsl:apply-templates mode="sub-nav-current-att" select="."/>
                      <span>
                        <xsl:apply-templates mode="nav-text" select="@display"/>
                      </span>
                      <ul>
                        <xsl:apply-templates mode="sub-nav" select="page | group"/>
                      </ul>
                    </li>
                  </xsl:template>


                  <!-- TODO: Find out whether nested lists should be supported. The JavaScript appears to be broken currently. -->
                  <xsl:template mode="sub-nav" match="page[ not(exists(./@hide)) ] ">
                    <li>
                        <xsl:apply-templates mode="sub-nav-current-att" select="."/>
                            <a href="{@href}">
                               <xsl:variable name="short-description"
                                             select="document(concat(@href, '.xml'))//ml:short-description"/>
                               <xsl:if test="$short-description">
                                    <xsl:attribute name="class">stip</xsl:attribute>
                                    <xsl:attribute name="title">
                                        <xsl:value-of select="$short-description"/>
                                    </xsl:attribute>
                                </xsl:if>
                                <xsl:apply-templates mode="nav-text" select="@display"/>
                            </a>
                    </li>
                  </xsl:template>

                          <xsl:template mode="sub-nav-current-att" match="*"/>

                          <xsl:template mode="sub-nav-current-att" match="*[. intersect $page-in-navigation/ancestor-or-self::*]">
                            <xsl:attribute name="class">current</xsl:attribute>
                          </xsl:template>

                          <!-- Exception: don't expand when initial expansion is explicitly disabled. This is useful
                               for the "Blog" navigation in particular, where a post may appear in multiple places in the sub-navigation.
                          -->
                          <xsl:template mode="sub-nav-current-att" match="group[@disable-initial-expansion eq 'yes']//page" priority="1"/>


          <xsl:template mode="sub-nav" match="blog-posts-grouped-by-date">
            <xsl:variable name="tree">
            </xsl:variable>
          </xsl:template>


  <!-- The <body> CSS class varies from page to page -->
  <xsl:template match="xhtml:body/@ml:class">
    <xsl:attribute name="class">
      <xsl:apply-templates mode="body-class"        select="$page-in-navigation[1]"/>
      <xsl:apply-templates mode="body-class-extra"  select="$page-in-navigation[1]"/>
    </xsl:attribute>
  </xsl:template>

          <xsl:template mode="body-class" match="page[@closed eq 'yes']
                                               | page[@closed eq 'yes']//page">blog</xsl:template>
          <xsl:template mode="body-class" match="*"/>

          <!-- TODO: get rid of this eventually, but for now, keep it around because we may want to use it as a base to tweak once we add the home page -->
          <xsl:template mode="body-class-extra" match="*"/>
          <xsl:template mode="body-class-extra" match="page[@href eq '/']                                  "> home</xsl:template>
          <xsl:template mode="body-class-extra" match="Article                                             "> layout2</xsl:template>
          <xsl:template mode="body-class-extra" match="page[ancestor-or-self::page/@narrow-sidebar = 'yes']"> layout3</xsl:template>

          <xsl:template mode="body-class-extra" match="@css-class">
            <xsl:text> </xsl:text>
            <xsl:value-of select="."/>
          </xsl:template>

  <xsl:template match="page-nav">
        <div class="pagination_nav">
            <xsl:if test="$content/page/@page/number() gt 1">
            <p class="pagination_prev"><a 
                href="{doc($content/page/@nav)/nav/page[position() = ($content/page/@page/number() - 1)]/@href/string()}" 
                class="btn btn_blue">&#171; Previous</a><span>
                <xsl:value-of select="doc($content/page/@nav)/nav/page[position() = ($content/page/@page/number() - 1)]/string()"/></span></p>
            </xsl:if>
            <xsl:if test="$content/page/@page/number() lt count(doc($content/page/@nav)/nav/page/number())">
            <p class="pagination_next"><a 
                href="{doc($content/page/@nav)/nav/page[position() = ($content/page/@page/number() + 1)]/@href/string()}" 
                class="btn btn_blue">Next &#187;</a><span> 
                <xsl:value-of select="doc($content/page/@nav)/nav/page[position() = ($content/page/@page/number() + 1)]/string()"/></span></p>
            </xsl:if>
        </div>
  </xsl:template>

  <xsl:template match="sub-nav[$content/page/@multi]">
      <section class="subnav">
      <h2>Contents</h2>
      <ul>
          <xsl:apply-templates mode="multi-page-toc" select="doc($content/page/@nav)/nav/page"/>
      </ul>
      </section>
  </xsl:template>

          <xsl:template mode="multi-page-toc" match="page">
            <li>
              <a href="{@href}" class="stip">
                <span>
                    <xsl:if test="position() = $content/ml:page/@page">
                        <xsl:attribute name="class">current-page</xsl:attribute>
                    </xsl:if>
                    <xsl:value-of select="string()"/>
                </span>
              </a>
            </li>
          </xsl:template>

</xsl:stylesheet>
