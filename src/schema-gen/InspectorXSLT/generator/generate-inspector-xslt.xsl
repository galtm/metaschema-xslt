<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:XSLT="http://www.w3.org/1999/XSL/Transform/alias"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:mx="http://csrc.nist.gov/ns/csd/metaschema-xslt"
   xpath-default-namespace="http://csrc.nist.gov/ns/oscal/metaschema/1.0" xmlns="http://www.w3.org/1999/xhtml"
   version="3.0">

   <!-- For extra integrity run Schematron inspector-generator-checkup.sch on this XSLT. -->

   <xsl:output indent="yes" encoding="us-ascii"/>
   <!-- pushing out upper ASCII using entity notation -->

   <xsl:namespace-alias stylesheet-prefix="XSLT" result-prefix="xsl"/>
   
   <!-- Maintaining the boilerplate out of line makes it easier to test and lint. -->
   <xsl:variable name="XSLT-template" as="document-node()" select="document('generator-boilerplate.xsl')"/>

   <xsl:variable name="metaschema-repository" as="xs:string">../../../../support/metaschema</xsl:variable>
   
   <xsl:variable name="atomictype-modules" as="element()*" expand-text="true">
      <module>{$metaschema-repository}/schema/xml/metaschema-datatypes.xsd</module>
   </xsl:variable>
   
   <xsl:variable name="type-definitions" select="document($atomictype-modules)"/>

   <!-- XSD definitions for the markup multiline types are here:

../../../../support/metaschema/schema/xml/metaschema-markup-multiline.xsd
../../../../support/metaschema/schema/xml/metaschema-markup-line.xsd

This XSLT needs to know of two categories:
  top-level markup-multiline i.e. headers and paragraphs
  inline markup-line i.e. inline elements permitted inside p-level elements
  
  intermediate and special cases such as ul, ol and table have handling in generator-boilerplate.xsl
  
-->
   
   <!-- markup multiline elements are
      //xs:element/@name => string-join(' ') from ../../../../support/metaschema/schema/xml/metaschema-markup-multiline.xsd
      h1 h2 h3 h4 h5 h6 p table img pre hr blockquote li ul ol p tr td th
      minus elements not permitted at the top, namely li, tr, td, th -->
   
   <xsl:variable name="markup-multiline-elements" select="'h1 h2 h3 h4 h5 h6 table img pre hr blockquote ul ol p' ! tokenize(.,' ')"/>
   
   <!-- //xs:element/@name => string-join(' ') from ../../../../support/metaschema/schema/xml/metaschema-prose-base.xsd -->
   <xsl:variable name="markup-inline-elements"
      select="'a insert br code em i b strong sub sup q img' ! tokenize(.,' ')"/>

   <xsl:variable name="xsd-ns-prefix" as="xs:string">xs:</xsl:variable>
   <!-- because we cannot assume a schema aware processor we look for a literal prefix for native XSD types -->
   
   <xsl:template match="/*">
      <XSLT:transform version="3.0" xpath-default-namespace="{ /METASCHEMA/namespace }" exclude-result-prefixes="#all">

         <xsl:comment expand-text="true"> Generated { current-dateTime() } </xsl:comment>

         <XSLT:mode on-no-match="fail"/>

         <XSLT:mode name="test" on-no-match="shallow-skip"/>

         <xsl:call-template name="comment-xsl">
            <xsl:with-param name="head">Templates copied from boilerplate</xsl:with-param>
         </xsl:call-template>

         <xsl:copy-of select="$XSLT-template/*/(child::* | child::comment())"/>

         <XSLT:template mode="metaschema-metadata" match="*">
            <mx:metaschema version="{/*/schema-version}" shortname="{/*/short-name}" namespace="{/*/namespace}">
               <xsl:text expand-text="true">{ /*/schema-name }</xsl:text>
            </mx:metaschema>
         </XSLT:template>

         <xsl:call-template name="comment-xsl">
            <xsl:with-param name="head">Generated rules - first, any roots</xsl:with-param>
         </xsl:call-template>

         <xsl:call-template name="comment-xsl">
            <xsl:with-param name="head"> Root </xsl:with-param>
         </xsl:call-template>
         <xsl:apply-templates select="define-assembly[exists(root-name)]" mode="require-of"/>

         <xsl:call-template name="comment-xsl">
            <xsl:with-param name="head"> Occurrences - templates in mode 'test' </xsl:with-param>
         </xsl:call-template>
         <!-- assembly references -->
         <xsl:apply-templates select="//assembly" mode="require-of"/>
         <!-- inline assembly definitions (i.e. references to themselves) -->
         <xsl:apply-templates select="//model//define-assembly" mode="require-of"/>
         <!-- field references -->
         <xsl:apply-templates select="//field" mode="require-of"/>
         <!-- inline field definitions (i.e. references to themselves) -->
         <xsl:apply-templates select="//model//define-field" mode="require-of"/>
         <!-- flag references -->
         <xsl:apply-templates select="//flag" mode="require-of"/>
         <!-- inline flag definitions (i.e. references to themselves) -->
         <xsl:apply-templates select="/*/define-assembly//define-flag | /*/define-field//define-flag" mode="require-of"/>

         <!-- We provide fallbacks for known elements matched out of context, to provide for errors when they appear out of place. -->
         <xsl:call-template name="comment-xsl">
            <xsl:with-param name="head"> Fallbacks for occurrences of known elements and attributes, except out of
               context </xsl:with-param>
         </xsl:call-template>

         <xsl:variable name="known-elements"
            select="(/*/*/root-name/parent::define-assembly | //model//define-assembly | //model//define-field | //assembly | //field)[not(@in-xml = 'UNWRAPPED')]/mx:use-name(.) => distinct-values()"/>
         <XSLT:template mode="test" match="{ $known-elements => string-join(' | ') }">
            <XSLT:call-template name="notice">
               <XSLT:with-param name="cf" as="xs:string">gix.108</XSLT:with-param>
               <XSLT:with-param name="class">EOOP element-out-of-place</XSLT:with-param>
               <XSLT:with-param name="msg" expand-text="true">Element <mx:gi>{ name() }</mx:gi> is not permitted here.</XSLT:with-param>
            </XSLT:call-template>
         </XSLT:template>
         <xsl:variable name="known-attributes"
            select="((//flag | //define-assembly/define-flag | define-field/define-flag)/mx:use-name(.) => distinct-values()) ! ('@' || .)"/>
         <XSLT:template mode="test" match="{ $known-attributes => string-join(' | ') }">
            <XSLT:call-template name="notice">
               <XSLT:with-param name="cf" as="xs:string">gix.117</XSLT:with-param>
               <XSLT:with-param name="class">AOOP attribute-out-of-place</XSLT:with-param>
               <XSLT:with-param name="msg" expand-text="true">Attribute <mx:gi>@{ name() }</mx:gi> is not permitted here.</XSLT:with-param>
            </XSLT:call-template>
         </XSLT:template>

         <xsl:call-template name="comment-xsl">
            <xsl:with-param name="head"> Definitions - a named template for each </xsl:with-param>
         </xsl:call-template>
         <xsl:apply-templates select="//define-assembly | //define-field | //define-flag" mode="require-for"/>

         <xsl:call-template name="comment-xsl">
            <xsl:with-param name="head"> Datatypes - a named template for each occurring </xsl:with-param>
         </xsl:call-template>

         <xsl:variable name="used-types"
            select="('string', //@as-type/string(.), //constraint/matches/@datatype/string(.))[not(. = ('markup-line', 'markup-multiline'))] => distinct-values()"/>
         <xsl:iterate select="$used-types" expand-text="true">
            <xsl:variable name="this-type" select="."/>
            <xsl:variable name="simpleType-name" select="$type-map[@as-type = $this-type]/string(.)"/>
            <XSLT:template name="check-{ . }-datatype">
               <XSLT:param name="rule-id" as="xs:string*" select="()"/>
               <XSLT:param name="class" as="xs:string">VDSX violates-datatype-syntax</XSLT:param>
               <XSLT:param name="matching" as="xs:string?" select="()"/>
               <xsl:variable name="assert" as="xs:string?" expand-text="true">
                  <xsl:apply-templates select="key('simpleType-by-name', $simpleType-name, $type-definitions)"
                     mode="datatype-test">
                     <xsl:with-param name="as-type-name" select="$this-type"/>
                  </xsl:apply-templates>
               </xsl:variable>
               <XSLT:call-template name="notice">
                  <XSLT:with-param name="cf" as="xs:string">gix.148</XSLT:with-param>
                  <XSLT:with-param name="rule-id" as="xs:string*" select="$rule-id"/>
                  <XSLT:with-param name="matching" as="xs:string" select="($matching[matches(.,'\S')],'*')[1]"/>
                  <XSLT:with-param name="class" as="xs:string" expand-text="true">{{ $class }}</XSLT:with-param>
                  <XSLT:with-param name="testing" as="xs:string">not({$assert})</XSLT:with-param>
                  <XSLT:with-param name="condition" select="not({$assert})"/>
                  <XSLT:with-param name="msg" expand-text="true">Value <mx:code>{{ string(.) }}</mx:code> of {{ if (self::element()) then 'element' else 'attribute' }} <mx:gi>{{ self::attribute()/'@' }}{{ name(.) }}</mx:gi> does not conform to <mx:code>{ $this-type }</mx:code> datatype.</XSLT:with-param>
               </XSLT:call-template>
            </XSLT:template>
         </xsl:iterate>

         <!-- empty templates in 'test' mode for expected markup elements -->
         <xsl:for-each-group
            select="/descendant::*[@as-type='markup-line']/key('using-name',mx:use-name(.))" group-by="mx:use-name(.)">
            <XSLT:template mode="test" match="{ $markup-inline-elements ! ( current-grouping-key() || '/' || .) => string-join('|') }"/>
         </xsl:for-each-group>
         
         
<!-- Selecting inline definitions and references marked as UNWRAPPED - these are all markup-multiline -->
         <xsl:for-each-group
            select="/descendant::model//*[mx:is-markup-multiline(.)][@in-xml='UNWRAPPED']" group-by="mx:match-name-with-parent(ancestor::model[1]/parent::*)">
<!-- matching elements containing unwrapped markup-multiline where it appears - there should only be one          -->
            <xsl:variable name="matches" select="$markup-multiline-elements ! ( current-grouping-key() || '/' || .) => string-join('|')"/>
            <XSLT:template mode="test" match="{$matches }">
               <xsl:call-template name="test-order"/>
            </XSLT:template>
         </xsl:for-each-group>
         
<!-- And producing templates for wrapped markup-multiline as well        -->
         
         <xsl:for-each-group
            select="/descendant::model//*[mx:is-markup-multiline(.)][not(@in-xml='UNWRAPPED')]" group-by="mx:match-name-with-parent(.)">            
            <xsl:variable name="matches" select="$markup-multiline-elements ! ( current-grouping-key() || '/' || .) => string-join('|')"/>
            <XSLT:template mode="test" match="{$matches }">
               <xsl:call-template name="test-order"/>
            </XSLT:template>
         </xsl:for-each-group>

         <xsl:for-each-group
            select="/descendant::model//*[mx:is-markup-line(.)]" group-by="mx:match-name-with-parent(.)">
            <!-- matching elements containing unwrapped markup-multiline where it appears - there should only be one          -->
            <xsl:variable name="matches" select="$markup-inline-elements ! ( current-grouping-key() || '/' || .) => string-join('|')"/>
            <XSLT:template mode="test" match="{$matches }">
               <xsl:call-template name="test-order"/>
            </XSLT:template>
         </xsl:for-each-group>
         
         <xsl:iterate select="$markup-inline-elements">
            <xsl:variable name="e" select="."/>
            <xsl:variable name="pattern-splice" as="function(*)" select="function($p as xs:string, $e as xs:string) as xs:string { $p || '/' || $e }"/>
            <xsl:variable name="empties" select="'img','hr','br'"/>
            <XSLT:template mode="test" match="{ $markup-multiline-elements[not(.=$empties)] ! $pattern-splice( .,$e) => string-join('|') }"/>
            <XSLT:template mode="test" match="{ $markup-inline-elements[not(.=$empties)] ! $pattern-splice( .,$e) => string-join('|') }"/>
         </xsl:iterate>
         
      </XSLT:transform>
   </xsl:template>

   <xsl:function name="mx:is-markup-multiline" as="xs:boolean">
      <xsl:param name="who" as="node()"/>
      <xsl:sequence select="$who/(. | key('field-definitions',$who/@_key-ref))/@as-type='markup-multiline'"/>
   </xsl:function>
   
   <xsl:function name="mx:is-markup-line" as="xs:boolean">
      <xsl:param name="who" as="node()"/>
      <xsl:sequence select="$who/(. | key('field-definitions',$who/@_key-ref))/@as-type='markup-line'"/>
   </xsl:function>
   
   
   <xsl:key name="simpleType-by-name" match="xs:simpleType" use="@name"/>

   <xsl:template match="/*/*" priority="0.25"/>

   <!-- Assuming composed Metaschema input with disambiguated keys -->
   <xsl:key name="assembly-definitions" match="/METASCHEMA/define-assembly" use="@_key-name"/>
   <xsl:key name="field-definitions" match="/METASCHEMA/define-field" use="@_key-name"/>
   <xsl:key name="flag-definitions" match="/METASCHEMA/define-flag" use="@_key-name"/>

   <xsl:key name="flag-references" match="flag" use="@_key-ref"/>
   <xsl:key name="field-references" match="field" use="@_key-ref"/>
   <xsl:key name="assembly-references" match="assembly" use="@_key-ref"/>

   <xsl:key name="using-name" match="flag | field | assembly | define-flag | define-field | define-assembly"
      use="mx:use-name(.)"/>

   <!-- 'require-of' mode encapsulates tests on any occurrence of any node, as represented by its reference or inline definition -->

   <xsl:template mode="require-of" match="define-assembly[exists(root-name)]" expand-text="true">
      <xsl:variable name="matching" select="mx:use-name(.)"/>
      <XSLT:template match="/{ $matching }" mode="test">
         <!-- nothing to test for cardinality or order -->

         <XSLT:apply-templates select="@*" mode="test"/>
         <XSLT:call-template name="require-for-{ mx:definition-name(.) }-assembly"/>
         <XSLT:apply-templates select="." mode="constraint-cascade"/>
      </XSLT:template>
      <xsl:apply-templates select="constraint" mode="generate-constraint-cascade">
         <xsl:with-param name="matching" as="xs:string+" tunnel="true" select="$matching"/>
      </xsl:apply-templates>
   </xsl:template>

   <!-- nothing required for unwrapped fields... -->
   <xsl:template mode="require-of" priority="10"
      match="field[@in-xml = 'UNWRAPPED'] | model//define-field[@in-xml = 'UNWRAPPED']"/>


   <xsl:template mode="require-of" expand-text="true"
      match="assembly | model//define-assembly | field | model//define-field">
      <xsl:variable name="metaschema-type" select="
            if (ends-with(local-name(), 'assembly')) then
               'assembly'
            else
               'field'"/>
      <xsl:variable name="using-name" select="mx:match-name(.)"/>

      <!-- matches(.,'\S') filters out matches that come back empty for assemblies never called -->
      <xsl:variable name="matches" as="xs:string*"
         select="(mx:contextualized-matches(ancestor::define-assembly[1]) ! (. || '/' || $using-name))[matches(., '\S')]"/>

      <xsl:if test="
            some $m in ($matches)
               satisfies matches($m, '\S')">
         <xsl:for-each select="self::field | self::define-field">
            <XSLT:template match="{ ($matches ! (. || '/text()') )  => string-join(' | ') }" mode="test"/>
         </xsl:for-each>

         <!-- test ordering with respect to parent when grouped   -->
         <xsl:if test="group-as/@in-xml = 'GROUPED'">
            <XSLT:template match="{ $matches ! replace(.,'/[^/]*$','') }" mode="test">
               <xsl:call-template name="test-order"/>
            </XSLT:template>
         </xsl:if>

         <XSLT:template priority="5" match="{ $matches => string-join(' | ') }" mode="test">
            <XSLT:apply-templates select="@*" mode="test"/>
            <!-- 'test-occurrence' template produces only tests needed to check this occurrence -->
            <xsl:call-template name="test-occurrence">
               <xsl:with-param name="using-name" select="$using-name"/>
            </xsl:call-template>
            <!-- while the containment, modeling or datatyping rule is held in a template for the applicable definition -->
            <XSLT:call-template name="require-for-{ mx:definition-name(.) }-{ $metaschema-type }">
               <!--<xsl:if test="exists(use-name)">
          <XSLT:with-param as="xs:string" tunnel="true" name="matching">{ $using-name }</XSLT:with-param>
        </xsl:if>-->
            </XSLT:call-template>
            <XSLT:apply-templates mode="constraint-cascade" select="."/>
         </XSLT:template>
         <xsl:apply-templates select="constraint" mode="generate-constraint-cascade">
            <xsl:with-param name="matching" as="xs:string+" tunnel="true" select="$matches"/>
         </xsl:apply-templates>
      </xsl:if>
   </xsl:template>

   <!--mode required-of -->

   <xsl:template mode="require-of" expand-text="true"
      match="flag | /*/define-field/define-flag | /*/define-assembly//define-flag">
      <xsl:variable name="using-name" select="mx:use-name(.)"/>
      <xsl:variable name="parentage"
         select="(ancestor::define-field[1] | ancestor::define-assembly[1])/mx:contextualized-matches(.)"/>
      <!-- guarding against making broken templates for definitions never used (hence no parentage) -->
      <xsl:if test="exists($parentage)">
         <xsl:variable name="matches"
            select="($parentage[matches(., '\S')] ! (. || '/@' || $using-name)) => string-join(' | ')"/>
         <XSLT:template match="{ $matches }" mode="test">
            <!-- no occurrence testing for flags -->
            <!-- datatyping rule -->
            <XSLT:call-template name="require-for-{ mx:definition-name(.) }-flag">
               <!--<xsl:if test="exists(use-name)">
          <XSLT:with-param as="xs:string" tunnel="true" name="matching">{ $using-name }</XSLT:with-param>
        </xsl:if>-->
            </XSLT:call-template>
            <XSLT:apply-templates mode="constraint-cascade" select="."/>
         </XSLT:template>
         <xsl:apply-templates select="constraint | key('flag-definitions', @_key-ref)/constraint" mode="generate-constraint-cascade">
            <xsl:with-param name="matching" as="xs:string+" tunnel="true" select="$matches"/>
         </xsl:apply-templates>
      </xsl:if>
   </xsl:template>

   <xsl:template name="test-occurrence" expand-text="true">
      <xsl:param name="using-name" required="true"/>
      <!-- test for cardinality -->
      <xsl:if test="number(@min-occurs) gt 1">
         <xsl:variable name="min" select="(@min-occurs, 1)[1]"/>
         <xsl:variable name="test" as="xs:string">empty(following-sibling::{$using-name}) and (count(. | preceding-sibling::{$using-name}) lt {$min})</xsl:variable>
         <!--empty(following-sibling::fan) and (count(. | preceding-sibling::fan) lt 2)-->
         <XSLT:call-template name="notice">
            <XSLT:with-param name="cf">gix.336</XSLT:with-param>
            <XSLT:with-param name="class">EATI element-appears-too-infrequently</XSLT:with-param>
            <XSLT:with-param name="testing" as="xs:string">{$test}</XSLT:with-param>
            <XSLT:with-param name="condition" select="{$test}"/>
            <XSLT:with-param name="msg">Element <mx:gi>{ mx:use-name(.) }</mx:gi> appears too few times: { $min } minimum are required.</XSLT:with-param>
         </XSLT:call-template>
      </xsl:if>
      <xsl:if test="not(@max-occurs = 'unbounded')">
         <xsl:variable name="max" select="(@max-occurs ! number(), 1)[1]"/>
         <xsl:variable name="test" as="xs:string">count(. | preceding-sibling::{$using-name}) gt {$max}</xsl:variable>
         <XSLT:call-template name="notice">
            <XSLT:with-param name="cf">gix.347</XSLT:with-param>
            <XSLT:with-param name="class">EATO element-appears-too-often</XSLT:with-param>
            <XSLT:with-param name="testing" as="xs:string">{$test}</XSLT:with-param>
            <XSLT:with-param name="condition" select="{$test}"/>
            <XSLT:with-param name="msg">Element <mx:gi>{ mx:use-name(.) }</mx:gi> appears too many times: { $max } maximum { if
               ($max eq 1) then 'is' else 'are' } permitted.</XSLT:with-param>
         </XSLT:call-template>
      </xsl:if>

      <xsl:if test="exists(parent::choice)">
         <!-- opting to be a little noisy - reporting for all exclusive choices given -->
         <xsl:variable name="alternatives" select="(parent::choice/child::* except .)"/>
         <xsl:variable name="test" as="xs:string">empty(preceding-sibling::{$using-name}) and exists(../({
            ($alternatives ! mx:use-name(.)) => string-join(' | ') }))</xsl:variable>
         <XSLT:call-template name="notice">
            <XSLT:with-param name="cf">gix.362</XSLT:with-param>
            <XSLT:with-param name="testing" as="xs:string">{$test}</XSLT:with-param>
            <XSLT:with-param name="condition" select="{$test}"/>
            <XSLT:with-param name="class">VEXC violates-exclusive-choice</XSLT:with-param>
            <XSLT:with-param name="msg">Element <mx:gi>{ mx:use-name(.) }</mx:gi>
               <xsl:text> is unexpected along with </xsl:text>
               <xsl:call-template name="punctuate-or-code-sequence">
                  <xsl:with-param name="items" select="$alternatives"/>
               </xsl:call-template>
               <xsl:text>.</xsl:text>
            </XSLT:with-param>
         </XSLT:call-template>
      </xsl:if>

      <xsl:if test="not(group-as/@in-xml = 'GROUPED')">
         <xsl:call-template name="test-order"/>
      </xsl:if>
   </xsl:template>

   <xsl:template name="test-order">
      <xsl:param name="expected-followers" select="
            (following-sibling::field | following-sibling::assembly |
            following-sibling::define-field | following-sibling::define-assembly | following-sibling::choice/child::*) except (parent::choice/*)"/>
      <xsl:variable name="okay-followers" as="xs:string*" select="$expected-followers[not(@in-xml='UNWRAPPED')]/mx:select-name(.), $markup-multiline-elements[$expected-followers/@in-xml='UNWRAPPED']"/>
      <xsl:if test="exists($okay-followers)" expand-text="true">
         <xsl:variable name="interlopers" select="$okay-followers ! ('preceding-sibling::' || .) => string-join(' | ')"/>
         <xsl:variable name="test" as="xs:string">exists({$interlopers})</xsl:variable>
         <XSLT:call-template name="notice">
            <XSLT:with-param name="cf">gix.390</XSLT:with-param>
            <XSLT:with-param name="class">EOOO element-out-of-order</XSLT:with-param>
            <XSLT:with-param name="testing" as="xs:string">{$test}</XSLT:with-param>
            <XSLT:with-param name="condition" select="{$test}"/>
            <XSLT:with-param name="msg">Element <mx:gi>{ mx:use-name(.) }</mx:gi>
               <xsl:text> is unexpected following </xsl:text>
               <xsl:call-template name="punctuate-or-code-sequence">
                  <xsl:with-param name="items" select="$expected-followers"/>
               </xsl:call-template>
               <xsl:text>.</xsl:text>
            </XSLT:with-param>
         </XSLT:call-template>
      </xsl:if>
   </xsl:template>

   <xsl:template name="punctuate-or-code-sequence">
      <xsl:param name="items"/>
      <xsl:for-each select="$items" expand-text="true">
         <xsl:call-template name="punctuate-or-item"/>
         <mx:gi>{ mx:match-name(.) }</mx:gi>
      </xsl:for-each>
   </xsl:template>



   <!-- 'require-for' encapsulates tests on assembly, field or flag types as expressed per object: 
     - attribute requirements for assemblies and fields
     - content model requirements for assemblies
     - datatype requirements for fields (values) and flags -->

   <xsl:template mode="require-for" match="define-assembly" expand-text="true">
      <!--<xsl:variable name="has-unwrapped-markup-multiline" as="xs:boolean"
         select="exists((model/field | model/define-field | model/choice/field | model/choice/define-field)[@as-type = 'markup-multiline'][@in-xml = 'UNWRAPPED'])"/>-->
      <XSLT:template name="require-for-{ mx:definition-name(.) }-assembly">
         
         <xsl:call-template name="require-attributes"/>

         <xsl:for-each
            select="model/*[@min-occurs ! (number() ge 1)][not(@in-xml = 'UNWRAPPED')] | model/choice[empty(*[@min-occurs ! (number() eq 0)] | *[@in-xml = 'UNWRAPPED'])]"
            expand-text="true">
            <!-- XXX extend $requiring here to produce choices for choice -->
            <xsl:variable name="requiring">
               <xsl:choose>
                  <xsl:when test="self::choice">
                     <xsl:sequence
                        select="*[@min-occurs ! (number() ge 1)][not(@in-xml = 'UNWRAPPED')]/mx:match-name(.) => string-join('|')"
                     />
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:sequence select="mx:match-name(.)"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:variable>
            <xsl:variable name="test" as="xs:string">empty({$requiring})</xsl:variable>
            <XSLT:call-template name="notice">
               <XSLT:with-param name="cf">gix.445</XSLT:with-param>
               <XSLT:with-param name="class">MRQC missing-required-contents</XSLT:with-param>
               <XSLT:with-param name="testing" as="xs:string">{$test}</XSLT:with-param>
               <XSLT:with-param name="condition" select="{$test}"/>
               <XSLT:with-param name="msg" expand-text="true">Element <mx:gi>{{ name() }}</mx:gi> requires element <mx:gi>{ $requiring
                     }</mx:gi>.</XSLT:with-param>
            </XSLT:call-template>
         </xsl:for-each>
         <!--<xsl:if test="$has-unwrapped-markup-multiline"> no longer needed
            <XSLT:apply-templates mode="validate-markup-multiline"/>
         </xsl:if>-->
      </XSLT:template>
      
   </xsl:template>
   
   
   <xsl:template mode="require-for" match="define-field">
      <XSLT:template name="require-for-{ mx:definition-name(.) }-field">
         <xsl:call-template name="require-attributes"/>
         <xsl:for-each select="@as-type[. != ('string','markup-line','markup-multiline')]">
            <XSLT:call-template name="check-{ . }-datatype"/>
         </xsl:for-each>
      </XSLT:template>
   </xsl:template>

   <!--mode generate-constraint-cascade produces a template cascade effectuated by xsl:next-match -->

   <xsl:mode name="generate-constraint-cascade" on-no-match="fail"/>

   <xsl:variable name="constraint-count" select="count(//constraint/*)"/>

   <xsl:template mode="generate-constraint-cascade" match="constraint">
      <xsl:apply-templates select="*" mode="#current"/>
   </xsl:template>

   <xsl:template mode="generate-constraint-cascade" match="constraint/*">
      <xsl:message expand-text="true">matching {name()}{ @id ! ('[@id=' || . || ']')} we get no template for the constraint cascade</xsl:message>
      <xsl:apply-templates select="*" mode="#current"/>
   </xsl:template>

   <xsl:template mode="generate-constraint-cascade" priority="10" match="constraint/allowed-values" expand-text="true">
      <xsl:param name="matching" as="xs:string+" required="true" tunnel="true"/>
      <xsl:variable name="priority">
         <xsl:number count="constraint/*" level="any" format="10001"/>
      </xsl:variable>
      <xsl:variable name="target-step" expand-text="true">{ @target[not(matches(.,'^\s*\.\s*$'))] ! ('/(' || . || ')')
         }</xsl:variable>
      <xsl:variable name="target-match" select="($matching ! (. || $target-step)) => string-join(' | ')"/>
      <XSLT:template priority="{ ($constraint-count + 101) - number($priority) }" mode="constraint-cascade"
         match="{ $target-match }">

         <xsl:variable name="values" select="enum/@value"/>
         <xsl:variable name="value-sequence" select="($values ! ('''' || . || '''')) => string-join(',')"/>
         <xsl:variable name="assert" as="xs:string" expand-text="true">.=({$value-sequence})</xsl:variable>
         <!-- test is not type-safe -->
         <xsl:variable name="allowing-others" select="@allow-other = 'yes'"/>
         <XSLT:call-template name="notice">
            <XSLT:with-param name="cf">gix.502</XSLT:with-param>
            <XSLT:with-param name="rule-id">{ @id }</XSLT:with-param>
            <XSLT:with-param name="matching" as="xs:string">{ $target-match }</XSLT:with-param>
            <XSLT:with-param name="class">AVCV value-not-allowed</XSLT:with-param>
            <XSLT:with-param name="testing" as="xs:string">not({$assert})</XSLT:with-param>
            <XSLT:with-param name="condition" select="not({$assert})"/>
            <XSLT:with-param name="msg" expand-text="true">Value <mx:code>{{ string(.) }}</mx:code>{{ .[not(string(.))] ! ' (empty)' }} does not appear among permissible (enumerated) values for this <mx:gi>{{ name() }}</mx:gi>: <mx:code>{ $values => string-join('|') }</mx:code>.</XSLT:with-param>
            <XSLT:with-param name="level" select="'{ (@level,'WARNING'[$allowing-others],'ERROR')[1] }'"/>
         </XSLT:call-template>
         <XSLT:next-match/>
      </XSLT:template>

   </xsl:template>

   <xsl:template mode="generate-constraint-cascade" priority="10" match="constraint/matches" expand-text="true">
      <xsl:param name="matching" as="xs:string+" required="true" tunnel="true"/>
      <xsl:variable name="priority">
         <xsl:number count="constraint/*" level="any" format="10001"/>
      </xsl:variable>
      <xsl:variable name="target-step" expand-text="true">{ @target[not(matches(.,'\s*\.\s*'))] ! ('/(' || . || ')')
         }</xsl:variable>
      <xsl:variable name="target-match" select="($matching ! (. || $target-step)) => string-join(' | ')"/>
      <XSLT:template priority="{ ($constraint-count + 101) - number($priority) }" mode="constraint-cascade"
         match="{ $target-match }">
         <xsl:for-each select="@datatype">
            <XSLT:call-template name="check-{ . }-datatype">
               <XSLT:with-param name="rule-id">{ parent::matches/@id }</XSLT:with-param>
               <XSLT:with-param name="class" as="xs:string">MDCV datatype-match-fail</XSLT:with-param>
               <XSLT:with-param name="matching" as="xs:string">{ $target-match }</XSLT:with-param>
            </XSLT:call-template>
         </xsl:for-each>
         <xsl:for-each select="@regex">
            <xsl:variable name="assert" expand-text="true">matches(., '^{.}$')</xsl:variable>
            <XSLT:call-template name="notice">
               <XSLT:with-param name="cf">gix.536</XSLT:with-param>
               <XSLT:with-param name="rule-id">{ parent::matches/@id }</XSLT:with-param>
               <XSLT:with-param name="matching" as="xs:string">{ $target-match }</XSLT:with-param>
               <XSLT:with-param name="class">MRCV regex-match-fail</XSLT:with-param>
               <XSLT:with-param name="testing" as="xs:string">not({$assert})</XSLT:with-param>
               <XSLT:with-param name="condition" select="not({$assert})"/>
               <XSLT:with-param name="msg" expand-text="true"><mx:code>{{ string(.) }}</mx:code>{{ string(.)[not(.)] ! ' (empty)' }} does not match the regular expression defined for this <mx:gi>{{ name() }}</mx:gi>: <mx:code>{ . }</mx:code>.</XSLT:with-param>
            </XSLT:call-template>
         </xsl:for-each>
         <XSLT:next-match/>
      </XSLT:template>
   </xsl:template>

   <xsl:template mode="generate-constraint-cascade" priority="10" match="constraint/expect" expand-text="true">
      <xsl:param name="matching" as="xs:string+" required="true" tunnel="true"/>
      <xsl:variable name="priority">
         <xsl:number count="constraint/*" level="any" format="10001"/>
      </xsl:variable>
      <xsl:variable name="target-step" expand-text="true">{ @target[not(matches(.,'\s*\.\s*'))] ! ('/(' || . || ')')
         }</xsl:variable>
      <xsl:variable name="target-match" select="($matching ! (. || $target-step)) => string-join(' | ')"/>
      <xsl:variable name="assert" expand-text="true">{ @test }</xsl:variable>
      <XSLT:template priority="{ ($constraint-count + 101) - number($priority) }" mode="constraint-cascade"
         match="{ $target-match }">
         
         <!--<xsl:variable name="test" as="xs:string" expand-text="true">{ @test }</xsl:variable>-->
         <!-- test is not type-safe -->
         <XSLT:call-template name="notice">
            <XSLT:with-param name="cf">gix.564</XSLT:with-param>
            <XSLT:with-param name="rule-id">{ @id }</XSLT:with-param>
            <XSLT:with-param name="matching" as="xs:string">{ $target-match }</XSLT:with-param>
            <XSLT:with-param name="class">XPKT expectation-violation</XSLT:with-param>
            <XSLT:with-param name="testing" as="xs:string">not({$assert})</XSLT:with-param>
            <XSLT:with-param name="condition" select="not({$assert})"/>
            <XSLT:with-param name="msg" expand-text="true">Expression result for <mx:gi>{ $target-match }</mx:gi> does not conform to expectation <mx:code>{@test}</mx:code>.</XSLT:with-param>
         </XSLT:call-template>
         <XSLT:next-match/>
      </XSLT:template>
   </xsl:template>
   
   <xsl:template mode="generate-constraint-cascade" priority="10" match="constraint/has-cardinality" expand-text="true">
      <xsl:param name="matching" as="xs:string+" required="true" tunnel="true"/>
      <xsl:variable name="priority">
         <xsl:number count="constraint/*" level="any" format="10001"/>
      </xsl:variable>
      <xsl:variable name="count-expr" as="xs:string">count({ @target })</xsl:variable>
      <xsl:variable name="assert" expand-text="true">{
         (@min-occurs ! ($count-expr || ' ge ' || .),'true()')[1] } and {
         (@max-occurs ! ($count-expr || ' le ' || .),'true()')[1] }</xsl:variable>
      <XSLT:template priority="{ ($constraint-count + 101) - number($priority) }" mode="constraint-cascade"
         match="{ $matching }">
         <!-- test is not type-safe -->
         <XSLT:call-template name="notice">
            <XSLT:with-param name="cf">gix.589</XSLT:with-param>
            <XSLT:with-param name="rule-id">{ @id }</XSLT:with-param>
            <XSLT:with-param name="matching" as="xs:string">{ $matching }</XSLT:with-param>
            <XSLT:with-param name="class">HCCV cardinality-violation</XSLT:with-param>
            <XSLT:with-param name="testing" as="xs:string">not({$assert})</XSLT:with-param>
            <XSLT:with-param name="condition" select="not({$assert})"/>
            <XSLT:with-param name="msg" expand-text="true">Counting <mx:gi>{ @target }</mx:gi> under <mx:code>{ $matching }</mx:code> finds {{{$count-expr}}} - expecting { @min-occurs ! ('at least ' || . || (../@max-occurs !', ')) }{ @max-occurs ! ('no more than ' || .) }.</XSLT:with-param>
         </XSLT:call-template>
         <XSLT:next-match/>
      </XSLT:template>
   </xsl:template>
   <xsl:key name="index-by-name" match="index" use="@name"/>
   
   <xsl:template mode="generate-constraint-cascade" priority="10" match="constraint/index-has-key" expand-text="true">
      <xsl:param name="matching" as="xs:string+" required="true" tunnel="true"/>
      <xsl:variable name="key-definition" select="key('index-by-name',@name)"/>
      <xsl:variable name="priority">
         <xsl:number count="constraint/*" level="any" format="10001"/>
      </xsl:variable>
      <xsl:variable name="keyname" as="xs:string">
         <xsl:apply-templates select="." mode="make-key-name"/>
      </xsl:variable>
      
      <xsl:variable name="count-expr" expand-text="true">mx:key-matches-among-items(.,$selected,'{$keyname}',{mx:key-value(.)},$within)</xsl:variable>
      <xsl:variable name="assert" expand-text="true">exists({$count-expr})</xsl:variable>
      
      <XSLT:template priority="{ ($constraint-count + 101) - number($priority) }" mode="constraint-cascade"
         match="{ string-join($matching,'|') }">
         <XSLT:variable name="within" select="."/>
         <XSLT:variable name="selected" select="//{ mx:match-name($key-definition/parent::constraint/parent::*) || $key-definition/('/' || @target) }"/>
         <XSLT:for-each select="{ @target }">
            <XSLT:call-template name="notice">
               <XSLT:with-param name="cf">gix.621</XSLT:with-param>
               <XSLT:with-param name="rule-id">{ @id }</XSLT:with-param>
               <XSLT:with-param name="matching" as="xs:string">{ string-join($matching,'|')  }/({ @target})</XSLT:with-param>
               <XSLT:with-param name="class">NXHK index-lookup-fail</XSLT:with-param>
               <XSLT:with-param name="testing" as="xs:string">not({$assert})</XSLT:with-param>
               <XSLT:with-param name="condition" select="not({$assert})"/>
               <XSLT:with-param name="msg" expand-text="true">With respect to its assigned index { key-field[2]/'(compound) ' } value, this <mx:gi>{{name(.)}}</mx:gi> is expected to correspond within its <mx:gi>{{$within/name(.)}}</mx:gi> to a value listed under index <mx:b>{ @name }</mx:b>. This index has no entry under the key value{ key-field[2]/'s' } <mx:code>{{string-join(({mx:key-value(.)}),',')}}</mx:code>.</XSLT:with-param>
            </XSLT:call-template>       
         </XSLT:for-each>
         <XSLT:next-match/>
      </XSLT:template>
   </xsl:template>
   
   <xsl:template mode="generate-constraint-cascade" priority="10" match="constraint/index" expand-text="true">
      <xsl:param name="matching" as="xs:string+" required="true" tunnel="true"/>
      <xsl:variable name="priority">
         <xsl:number count="constraint/*" level="any" format="10001"/>
      </xsl:variable>
      <xsl:variable name="keyname" as="xs:string">
         <xsl:apply-templates select="." mode="make-key-name"/>
      </xsl:variable>
      <xsl:variable name="counting" select="@target"/>
      <xsl:apply-templates select="." mode="make-key">
         <xsl:with-param name="matching" as="xs:string*" select="$matching ! (. || '/(' || $counting || ')')"/>
      </xsl:apply-templates>
   </xsl:template>
   
   <xsl:template mode="generate-constraint-cascade" priority="10" match="constraint/is-unique" expand-text="true">
      <xsl:param name="matching" as="xs:string+" required="true" tunnel="true"/>
      <xsl:variable name="priority">
         <xsl:number count="constraint/*" level="any" format="10001"/>
      </xsl:variable>
      <xsl:variable name="keyname" as="xs:string">
         <xsl:apply-templates select="." mode="make-key-name"/>
      </xsl:variable>
     
      <xsl:variable name="count-expr" expand-text="true">mx:key-matches-among-items(.,$selected,'{$keyname}',({mx:key-value(.)}),$within)</xsl:variable>
      <xsl:variable name="assert" expand-text="true">count({$count-expr})=1</xsl:variable>
      
      <xsl:variable name="counting" select="@target"/>
      <xsl:apply-templates select="." mode="make-key">
         <xsl:with-param name="matching" as="xs:string*" select="$matching ! (. || '/(' || $counting || ')')"/>
      </xsl:apply-templates>
      <XSLT:template priority="{ ($constraint-count + 101) - number($priority) }" mode="constraint-cascade"
         match="{ string-join($matching,'|') }">
         <XSLT:variable name="within" select="."/>
         <XSLT:variable name="selected" select="{ @target }"/>
         <XSLT:for-each select="{ @target }">
            <XSLT:call-template name="notice">
               <XSLT:with-param name="cf">gix.670</XSLT:with-param>
               <XSLT:with-param name="rule-id">{ @id }</XSLT:with-param>
               <XSLT:with-param name="matching" as="xs:string">{  string-join($matching,'|')  }/({ @target})</XSLT:with-param>
               <XSLT:with-param name="class">UNIQ uniqueness-violation</XSLT:with-param>
               <XSLT:with-param name="testing" as="xs:string">not({$assert})</XSLT:with-param>
               <XSLT:with-param name="condition" select="not({$assert})"/>
               <XSLT:with-param name="msg" expand-text="true">With respect to its assigned <mx:gi>{ mx:key-value(.) }</mx:gi>, this <mx:gi>{{name(.)}}</mx:gi> instance of <mx:code>{ string-join($matching,'|')  }/({ @target})</mx:code> is expected to be unique within its <mx:gi>{{$within/name(.)}}</mx:gi>. {{count({$count-expr})}} items are found with the value{ key-field[2]/'s' } <mx:code>{{string-join(({mx:key-value(.)}),',')}}</mx:code>.</XSLT:with-param>
            </XSLT:call-template>       
         </XSLT:for-each>
         <XSLT:next-match/>
      </XSLT:template>
   </xsl:template>
   
   <xsl:function name="mx:key-value" as="xs:string">
      <xsl:param name="whose" as="element()"/>
      <!-- delimit values with ',' emitting 'string(/)' for any key-field with no @target or @target=('.','value()') -->
      <xsl:value-of>
         <xsl:iterate select="$whose/key-field">
            <xsl:if test="position() gt 1">,</xsl:if>
            <!--<xsl:if test="count(../*) gt 1">(</xsl:if>-->
            <xsl:text expand-text="true">({ @target//(.[not(. = ('.', 'value()'))], 'string(.)')[1] })</xsl:text>
            <xsl:for-each select="@pattern" expand-text="true">[matches(.,'^{.}$')] ! replace(.,'^{.}$','$1')</xsl:for-each>
            <!--<xsl:if test="count(../*) gt 1">)</xsl:if>-->
         </xsl:iterate>
      </xsl:value-of>
      
   </xsl:function>
   
   
   <xsl:template match="index | is-unique" mode="make-key">
      <xsl:param name="matching" as="xs:string*" required="true"/>
      <xsl:variable name="keyname">
         <xsl:apply-templates select="." mode="make-key-name"/>
      </xsl:variable>
      <XSLT:key name="{$keyname}" match="{$matching}" use="{mx:key-value(.)}">
         <xsl:if test="count(key-field) gt 1">
            <xsl:attribute name="composite">true</xsl:attribute>
         </xsl:if>
      </XSLT:key>
   </xsl:template>

   <xsl:template mode="make-key-name" match="index | index-has-key" as="xs:string">
      <xsl:value-of>
         <xsl:text>NDX_</xsl:text>
         <xsl:number count="index | is-unique" level="any"/>
      </xsl:value-of>
   </xsl:template>
   
   <xsl:template mode="make-key-name" match="is-unique" as="xs:string">
      <xsl:value-of>
         <xsl:text>UNQ_</xsl:text>
         <xsl:number count="index | is-unique" level="any"/>
      </xsl:value-of>
   </xsl:template>
   
   <xsl:template mode="make-key-name" priority="10"
      match="index[matches(@name,'\S')] | index-has-key[matches(@name,'\S')]" expand-text="true">NDX_{@name}</xsl:template>
   
   <xsl:template mode="make-key-name" priority="10" match="is-unique[exists(@id)]">
      <xsl:text expand-text="true">UNIQ_{ @id }</xsl:text>
   </xsl:template>
   
   <xsl:template mode="require-for" match="define-flag" expand-text="true">
      <XSLT:template name="require-for-{ mx:definition-name(.) }-flag">
         <!--<XSLT:param tunnel="true" name="matching" as="xs:string">{ (use-name,@name)[1] }</XSLT:param>-->

         <xsl:for-each select="@as-type">
            <XSLT:call-template name="check-{ . }-datatype"/>
         </xsl:for-each>
      </XSLT:template>
   </xsl:template>

   <xsl:template name="require-attributes">
      <!-- for each required attribute ... -->
      <xsl:for-each select="(flag | define-flag)[@required = 'yes']" expand-text="true">
         <xsl:variable name="requiring" select="mx:use-name(.)"/>
         <xsl:variable name="test" as="xs:string">empty(@{$requiring})</xsl:variable>
         <XSLT:call-template name="notice">
            <XSLT:with-param name="cf">gix.748</XSLT:with-param>
            <XSLT:with-param name="class">MRQA missing-required-attribute</XSLT:with-param>
            <XSLT:with-param name="testing" as="xs:string">{$test}</XSLT:with-param>
            <XSLT:with-param name="condition" select="{$test}"/>
            <XSLT:with-param name="msg" expand-text="true">Element <mx:gi>{{ name() }}</mx:gi> requires attribute <mx:gi>@{ $requiring }</mx:gi>.</XSLT:with-param>
         </XSLT:call-template>
      </xsl:for-each>
   </xsl:template>

   <xsl:variable name="type-map" as="element()*">
      <!-- maps from Metaschema datatype names to Metaschema XSD constructs
     cf https://pages.nist.gov/metaschema/specification/datatypes/ -->
      <type as-type="base64">Base64Datatype</type>
      <type as-type="boolean">BooleanDatatype</type>
      <type as-type="date">DateDatatype</type>
      <type as-type="date-time">DateTimeDatatype</type>
      <type as-type="date-time-with-timezone">DateTimeWithTimezoneDatatype</type>
      <type as-type="date-with-timezone">DateWithTimezoneDatatype</type>
      <type as-type="day-time-duration">DayTimeDurationDatatype</type>
      <type as-type="decimal">DecimalDatatype</type>
      <!-- Not supporting float or double -->
      <!--<xs:enumeration as-type="float">float</xs:enumeration> -->
      <!--<xs:enumeration as-type="double">double</xs:enumeration> -->
      <type as-type="email-address">EmailAddressDatatype</type>
      <type as-type="hostname">HostnameDatatype</type>
      <type as-type="integer">IntegerDatatype</type>
      <type as-type="ip-v4-address">IPV4AddressDatatype</type>
      <type as-type="ip-v6-address">IPV6AddressDatatype</type>
      <type as-type="non-negative-integer">NonNegativeIntegerDatatype</type>
      <type as-type="positive-integer">PositiveIntegerDatatype</type>
      <type as-type="string">StringDatatype</type>
      <type as-type="token">TokenDatatype</type>
      <type as-type="uri">URIDatatype</type>
      <type as-type="uri-reference">URIReferenceDatatype</type>
      <type as-type="uuid">UUIDDatatype</type>

      <!-- these old names are permitted for now, while only deprecated       -->
      <!--../../../schema/xml/metaschema.xsd line 1052 inside  /*/xs:simpleType[@name='SimpleDatatypesType']> -->
      <type prefer="base64" as-type="base64Binary">Base64Datatype</type>
      <type prefer="date-time" as-type="dateTime">DateTimeDatatype</type>
      <type prefer="date-time-with-timezone" as-type="dateTime-with-timezone">DateTimeWithTimezoneDatatype</type>
      <type prefer="email-address" as-type="email">EmailAddressDatatype</type>
      <type prefer="non-negative-integer" as-type="nonNegativeInteger">NonNegativeIntegerDatatype</type>
      <type prefer="positive-integer" as-type="positiveInteger">PositiveIntegerDatatype</type>
   </xsl:variable>


   <!-- Processing datatype definitions from external file -->
   <xsl:mode name="datatype-test" on-no-match="shallow-skip"/>

   <xsl:template match="*" mode="datatype-test" as="xs:string?"/>

   <xsl:template match="xs:simpleType" mode="base-type" as="xs:string?">
      <xsl:param name="so-far" select="()" as="xs:string*"/>
      <xsl:variable name="sourced-definition" select="key('simpleType-by-name', xs:restriction/@base, root())"/>
      <xsl:if test="not($sourced-definition/xs:restriction/@base = $so-far)"><!-- the sourced-type is okay, it doesn't point back into the chain -->
         <xsl:choose>
            <xsl:when test="empty($sourced-definition)" expand-text="true">{ xs:restriction/@base }</xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates select="$sourced-definition" mode="#current">
                  <xsl:with-param name="so-far" select="$so-far, string(@name)"/>
               </xsl:apply-templates>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:if>
   </xsl:template>
   
   <xsl:template match="xs:simpleType" mode="type-stack" as="element()*">
      <xsl:param name="so-far" select="()" as="element()*"/>
      <xsl:variable name="sourced-definition" select="key('simpleType-by-name', xs:restriction/@base, root())"/>
      <xsl:if test="not($sourced-definition/xs:restriction/@base = $so-far/@name)"><!-- the sourced-type is okay, it doesn't point back into the chain -->
         <xsl:choose>
            <xsl:when test="empty($sourced-definition)">
              <xsl:sequence select="$so-far"/>
               <xsl:apply-templates select="." mode="graft-simple-type"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates select="$sourced-definition" mode="#current">
                  <xsl:with-param name="so-far" as="element()*">
                     <xsl:sequence select="$so-far"/>
                     <xsl:apply-templates select="." mode="graft-simple-type"/>
                  </xsl:with-param>
               </xsl:apply-templates>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:if>
   </xsl:template>
   
<!-- mode graft-simple-type cleans up elements in the xs: namespace  -->
   <xsl:template match="xs:*" mode="graft-simple-type">
      <xsl:copy copy-namespaces="no">
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates select="child::*" mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="xs:simpleType" priority="101" mode="datatype-test" as="xs:string?">
      <xsl:param name="as-type-name" as="xs:string"/>
      <xsl:value-of>
      <xsl:variable name="simple-types" as="element(xs:simpleType)*">
         <xsl:apply-templates select="." mode="type-stack"/>
      </xsl:variable>
         <xsl:variable name="nominal-base-type" select="$simple-types/xs:restriction/@base[starts-with(.,$xsd-ns-prefix)]"/><!-- assuming the processor cannot process the QName as such for the namespace -->
      <xsl:text expand-text="true">string(.) castable as { $nominal-base-type }</xsl:text>
      <xsl:for-each-group select="$simple-types/xs:restriction/xs:pattern" group-by="@value">
         <xsl:text expand-text="true"> and matches(.,'^{ current-grouping-key() }$')</xsl:text>
      </xsl:for-each-group>
      </xsl:value-of>
   </xsl:template>
   
   <xsl:template match="xs:simpleType" mode="datatype-test" as="xs:string?">
      <xsl:param name="as-type-name" as="xs:string" required="true"/>
      <xsl:text expand-text="true">string(.) castable as {(xs:restriction/@base,@name)[1]}</xsl:text>
   </xsl:template>
   
   <xsl:template match="xs:simpleType[xs:restriction]" mode="datatype-test" as="xs:string?">
      <xsl:param name="as-type-name" as="xs:string" required="true"/>
      <xsl:variable name="extra">
         <xsl:apply-templates mode="#current"/>
      </xsl:variable>
      <xsl:text expand-text="true">string(.) castable as {(xs:restriction/@base,@name)[1]}{ $extra[normalize-space(.)] ! (' and ' || .)}</xsl:text>
   </xsl:template>

   <xsl:template match="xs:restriction" mode="datatype-test" as="xs:string?">
      <xsl:apply-templates mode="#current"/>
   </xsl:template>

   <xsl:template match="xs:pattern" mode="datatype-test" as="xs:string?">
      <xsl:text expand-text="true">matches(.,'^{@value}$')</xsl:text>
   </xsl:template>


   <!-- Functions make it happen -->
   
   <!-- For an inline or global definition, the name captures the ancestry;
        for references, the definition will be at the top level (only) -->
   <xsl:function name="mx:definition-name" as="xs:string">
      <xsl:param name="def" as="node()"/>
      <xsl:sequence
         select="($def/@ref/string(.), $def/(ancestor::define-assembly | ancestor::define-field | .)/@name => string-join('_..._'))[1]"
      />
   </xsl:function>

   <xsl:function name="mx:or" as="xs:string">
      <xsl:param name="items" as="item()*"/>
      <xsl:value-of>
         <xsl:iterate select="$items">
            <xsl:call-template name="punctuate-or-item"/>
            <xsl:sequence select="."/>
         </xsl:iterate>
      </xsl:value-of>
   </xsl:function>

   <xsl:template name="punctuate-or-item">
      <xsl:variable name="among-more-than-two" select="last() gt 2"/>
      <xsl:variable name="comes-last" select="position() = last()"/>
      <xsl:if test="position() gt 1">
         <xsl:if test="$among-more-than-two">,</xsl:if>
         <xsl:text> </xsl:text>
         <xsl:if test="$comes-last">or </xsl:if>
      </xsl:if>
   </xsl:template>

   <xsl:function name="mx:tag" as="element()" expand-text="true">
      <xsl:param name="n" as="xs:string"/>
      <mx:gi>{ $n }</mx:gi>
   </xsl:function>

   <!-- contextualized match name resolves assembly field and flag
     definitions to their names in context (including parents) whereever referenced -->
   <xsl:function name="mx:contextualized-matches" as="xs:string*">
      <xsl:param name="who" as="element()"/>
      <!-- for a reference, return the use-name and the use-name of the parent   -->
      <!-- for an inline definition, the same   -->
      <!-- for a global definition, find its points of reference -->
      <xsl:variable name="found-matches" as="xs:string*">
         <xsl:apply-templates select="$who" mode="name-used"/>
      </xsl:variable>
      <xsl:sequence select="$found-matches[matches(., '\S')]"/>
   </xsl:function>

   <xsl:template mode="name-used" match="model//*" as="xs:string">
      <xsl:text expand-text="true">{ mx:match-name(ancestor::model[1]/..) }/{ mx:match-name(.) }</xsl:text>
   </xsl:template>

   <xsl:template mode="name-used" match="METASCHEMA/define-assembly" as="xs:string*">
      <xsl:if test="exists(root-name)" expand-text="true">/{ root-name }</xsl:if>
      <xsl:apply-templates mode="#current" select="key('assembly-references', @_key-name)"/>
   </xsl:template>

   <xsl:template mode="name-used" match="METASCHEMA/define-field" as="xs:string*">
      <xsl:apply-templates mode="#current" select="key('field-references', @_key-name)"/>
   </xsl:template>

   <xsl:template mode="name-used" match="METASCHEMA/define-flag" as="xs:string*">
      <xsl:apply-templates mode="#current" select="key('flag-references', @_key-name)"/>
   </xsl:template>

   <!--for a grouped element, returns the element in its group, e.g. 'notes/note'-->
   <xsl:function name="mx:match-name" as="xs:string?">
      <xsl:param name="who" as="element()"/>
      <xsl:text expand-text="true">{ $who/group-as[@in-xml='GROUPED']/@name ! (. || '/') }{ mx:use-name($who) }</xsl:text>
   </xsl:function>
   
   <!--for a grouped element, returns the group, e.g. 'notes' for notes/note, but 'note' if the grouping is not explicit @in-xml='GROUPED'-->
   
   <xsl:function name="mx:select-name" as="xs:string?">
      <xsl:param name="who" as="element()"/>
      <xsl:text expand-text="true">{ ($who/group-as[@in-xml='GROUPED']/@name, mx:use-name($who))[1] }</xsl:text>
   </xsl:function>
   
   <xsl:mode name="select-name" on-no-match="fail"/>
   
   <xsl:template mode="select-name" as="xs:string" expand-text="true"
      match="field | assembly | define-field | define-assembly">{ mx:use-name(.) }</xsl:template>

   <xsl:template mode="select-name" as="xs:string" expand-text="true"
      priority="101" match="*[group-as/@in-xml='GROUPED']">{ group-as/@name }[exists({ mx:use-name(.) })]</xsl:template>

   <xsl:function name="mx:match-name-with-parent" as="xs:string?">
      <xsl:param name="who" as="element()"/>
      <xsl:text expand-text="true">{ $who/ancestor::model[1]/parent::*/(mx:match-name(.) || '/') }{ mx:match-name($who) }</xsl:text>
   </xsl:function>

   <xsl:function name="mx:use-name" as="xs:string?">
      <xsl:param name="who" as="element()"/>
      <xsl:variable name="definition" select="
            $who/self::assembly/key('assembly-definitions', @_key-ref) |
            $who/self::field/key('field-definitions', @_key-ref) | $who/self::flag/key('flag-definitions', @_key-ref)"/>
      <xsl:sequence
         select="($who/root-name, $who/use-name, $definition/root-name, $definition/use-name, $definition/@name, $who/@name)[1]"
      />
   </xsl:function>

   <xsl:template name="comment-xsl">
      <xsl:param name="head"/>
      <xsl:comment> .     .     .     .     .     .     .     .     .     .     .     .     .     .     .     .     . </xsl:comment>
      <xsl:for-each select="$head">
         <xsl:comment>
        <xsl:text>    </xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>    </xsl:text>
      </xsl:comment>
         <xsl:text>&#xA;</xsl:text>
      </xsl:for-each>
      <xsl:comment> .     .     .     .     .     .     .     .     .     .     .     .     .     .     .     .     . </xsl:comment>
   </xsl:template>

</xsl:stylesheet>