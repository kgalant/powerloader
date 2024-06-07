<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output omit-xml-declaration="yes" indent="yes"/>

	<!-- 	<xsl:output method="spring:beans" doctype-system="http://www.springframework.org/dtd/spring-beans.dtd" doctype-public="-//SPRING//DTD BEAN//EN" indent="yes" /> -->

	<xsl:param name="batchsize"/> 				<!-- <entry key="sfdc.loadBatchSize" value="500"/> -->
	<xsl:param name="bulkapi"/> <!-- <entry key="sfdc.useBulkApi" value="BULKAPI"/> -->
	<xsl:param name="bulkapizipcontent"/> <!-- <entry key="sfdc.bulkApiZipContent" value="BULKAPIZIPCONTENT"/> -->
	<xsl:param name="bulkapiserial"/> <!-- <entry key="sfdc.bulkApiSerialMode value="BULKAPI"/> -->
	<xsl:param name="csv"/> <!-- <entry key="dataAccess.name" value="CSVOUTPUT"/> -->
	<xsl:param name="dataaccess"/> <!-- <entry key="dataAccess.type" value="DATAACCESS"/> -->
	<xsl:param name="endpoint"/> <!-- <entry key="sfdc.endpoint" value="ENDPOINT"/>  -->
	<xsl:param name="entity"/> <!-- <entry key="sfdc.entity" value="ENTITY"/> -->
	<xsl:param name="errorfile"/> <!-- <entry key="process.outputError" value="LOGDIR"/> -->
	<xsl:param name="externalid"/> <!-- <entry key="sfdc.externalIdField" value="EXTERNALID"/> -->
	<xsl:param name="logdir"/> <!-- <entry key="process.statusOutputDirectory" value="EXTERNALID"/> -->
	<xsl:param name="mappingfile"/> <!-- <entry key="process.mappingFile" value="MAPPINGFILE"/> -->
	<xsl:param name="operation"/> <!-- <entry key="process.operation" value="OPERATION"/> -->
	<xsl:param name="password"/> <!-- <entry key="sfdc.password" value="PASSWORD"/> -->
	<xsl:param name="soql"/> <!-- <entry key="sfdc.extractionSOQL" value="SOQL"/>  SELECT Id, name FROM Account -->
	<xsl:param name="successfile"/><!-- <entry key="process.outputSuccess" value="LOGDIR"/> -->
	<xsl:param name="username"/>  <!-- <entry key="sfdc.username" value="USERNAME"/> -->
	<xsl:param name="keyfile"/>  <!-- <entry key=process.encryptionKeyFile" value="c:\Users\{user}\.dataloader\dataLoader.key"/> -->


	<!-- <entry key="process.statusOutputDirectory" value="LOGDIR"/> -->


	<xsl:template match="node()|@*">
		<xsl:copy>
			<xsl:apply-templates select="node()|@*"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="beans/bean[@id='standard']/property[@name='configOverrideMap']/map">
		<xsl:copy>
			<xsl:apply-templates select="node()|@*"/>
			<xsl:choose>
				<xsl:when test="$batchsize">
					<entry>
						<xsl:attribute name='key'>sfdc.loadBatchSize</xsl:attribute>
						<xsl:attribute name='value'><xsl:value-of select="$batchsize" /></xsl:attribute>
					</entry>
				</xsl:when>
			</xsl:choose>
			
			<xsl:choose>
				<xsl:when test="$bulkapi">
					<entry>
						<xsl:attribute name='key'>sfdc.useBulkApi</xsl:attribute>
						<xsl:attribute name='value'><xsl:value-of select="$bulkapi"/></xsl:attribute>
					</entry>
				</xsl:when>
			</xsl:choose>

			<xsl:choose>
				<xsl:when test="$bulkapizipcontent">
					<entry>
						<xsl:attribute name='key'>sfdc.bulkApiZipContent</xsl:attribute>
						<xsl:attribute name='value'><xsl:value-of select="$bulkapizipcontent"/></xsl:attribute>
					</entry>
				</xsl:when>
			</xsl:choose>
			
			<xsl:choose>
				<xsl:when test="$bulkapiserial">
					<entry>
						<xsl:attribute name='key'>sfdc.bulkApiSerialMode</xsl:attribute>
						<xsl:attribute name='value'><xsl:value-of select="$bulkapiserial"/></xsl:attribute>
					</entry>
				</xsl:when>
			</xsl:choose>
			
			<xsl:choose>
				<xsl:when test="$csv">
					<entry>
						<xsl:attribute name='key'>dataAccess.name</xsl:attribute>
						<xsl:attribute name='value'><xsl:value-of select="$csv"/></xsl:attribute>
					</entry>
				</xsl:when>
			</xsl:choose>
			
			<xsl:choose>
				<xsl:when test="$dataaccess">
					<entry>
						<xsl:attribute name='key'>dataAccess.type</xsl:attribute>
						<xsl:attribute name='value'><xsl:value-of select="$dataaccess"/></xsl:attribute>
					</entry>
				</xsl:when>
			</xsl:choose>
			
			<xsl:choose>
				<xsl:when test="$endpoint">
					<entry>
						<xsl:attribute name='key'>sfdc.endpoint</xsl:attribute>
						<xsl:attribute name='value'><xsl:value-of select="$endpoint"/></xsl:attribute>
					</entry>
				</xsl:when>
			</xsl:choose>
			
			<xsl:choose>
				<xsl:when test="$entity">
					<entry>
						<xsl:attribute name='key'>sfdc.entity</xsl:attribute>
						<xsl:attribute name='value'><xsl:value-of select="$entity"/></xsl:attribute>
					</entry>
				</xsl:when>
			</xsl:choose>
			
			<xsl:choose>
				<xsl:when test="$errorfile">
					<entry>
						<xsl:attribute name='key'>process.outputError</xsl:attribute>
						<xsl:attribute name='value'><xsl:value-of select="$errorfile"/></xsl:attribute>
					</entry>
				</xsl:when>
			</xsl:choose>
			
			<xsl:choose>
				<xsl:when test="$externalid">
					<entry>
						<xsl:attribute name='key'>sfdc.externalIdField</xsl:attribute>
						<xsl:attribute name='value'><xsl:value-of select="$externalid"/></xsl:attribute>
					</entry>
				</xsl:when>
			</xsl:choose>
			
			<xsl:choose>
				<xsl:when test="$logdir">
					<entry>
						<xsl:attribute name='key'>process.statusOutputDirectory</xsl:attribute>
						<xsl:attribute name='value'><xsl:value-of select="$logdir"/></xsl:attribute>
					</entry>
				</xsl:when>
			</xsl:choose>

			<xsl:choose>
				<xsl:when test="$mappingfile">
					<entry>
						<xsl:attribute name='key'>process.mappingFile</xsl:attribute>
						<xsl:attribute name='value'><xsl:value-of select="$mappingfile"/></xsl:attribute>
					</entry>
				</xsl:when>
			</xsl:choose>
			
			<xsl:choose>
				<xsl:when test="$operation">
					<entry>
						<xsl:attribute name='key'>process.operation</xsl:attribute>
						<xsl:attribute name='value'><xsl:value-of select="$operation"/></xsl:attribute>
					</entry>
				</xsl:when>
			</xsl:choose>
			
			<xsl:choose>
				<xsl:when test="$password">
					<entry>
						<xsl:attribute name='key'>sfdc.password</xsl:attribute>
						<xsl:attribute name='value'><xsl:value-of select="$password"/></xsl:attribute>
					</entry>
				</xsl:when>
			</xsl:choose>
			
			<xsl:choose>
				<xsl:when test="$soql">
					<entry>
						<xsl:attribute name='key'>sfdc.extractionSOQL</xsl:attribute>
						<xsl:attribute name='value'><xsl:value-of select="$soql"/></xsl:attribute>
					</entry>
				</xsl:when>
			</xsl:choose>
			
			<xsl:choose>
				<xsl:when test="$successfile">
					<entry>
						<xsl:attribute name='key'>process.outputSuccess</xsl:attribute>
						<xsl:attribute name='value'><xsl:value-of select="$successfile"/></xsl:attribute>
					</entry>
				</xsl:when>
			</xsl:choose>
			
			<xsl:choose>
				<xsl:when test="$username">
					<entry>
						<xsl:attribute name='key'>sfdc.username</xsl:attribute>
						<xsl:attribute name='value'><xsl:value-of select="$username"/></xsl:attribute>
					</entry>
				</xsl:when>
			</xsl:choose>

			<xsl:choose>
				<xsl:when test="$keyfile">
					<entry>
						<xsl:attribute name='key'>process.encryptionKeyFile</xsl:attribute>
						<xsl:attribute name='value'><xsl:value-of select="$keyfile"/></xsl:attribute>
					</entry>
				</xsl:when>
			</xsl:choose>
		</xsl:copy>
	</xsl:template>

	<!-- <xsl:template match="@value[parent::entry[@key='sfdc.loadBatchSize']]">
		<xsl:attribute name="value">
			<xsl:choose>
				<xsl:when test="not($batchsize)">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$batchsize"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>

	<xsl:template match="@value[parent::entry[@key='process.outputError']]">
		<xsl:attribute name="value">
			<xsl:choose>
				<xsl:when test="not($errorfile)">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$errorfile"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>

	<xsl:template match="@value[parent::entry[@key='process.outputSuccess']]">
		<xsl:attribute name="value">
			<xsl:choose>
				<xsl:when test="not($successfile)">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$successfile"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>

	<xsl:template match="@value[parent::entry[@key='sfdc.externalIdField']]">
		<xsl:attribute name="value">
			<xsl:choose>
				<xsl:when test="not($externalid)">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$externalid"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>

	<xsl:template match="@value[parent::entry[@key='dataAccess.name']]">
		<xsl:attribute name="value">
			<xsl:choose>
				<xsl:when test="not($csv)">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$csv"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>

	<xsl:template match="@value[parent::entry[@key='sfdc.useBulkApi']]">
		<xsl:attribute name="value">
			<xsl:choose>
				<xsl:when test="not($bulkapi)">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$bulkapi"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>

	<xsl:template match="@value[parent::entry[@key='sfdc.bulkApiSerialMode']]">
		<xsl:attribute name="value">
			<xsl:choose>
				<xsl:when test="not($bulkapiserial)">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$bulkapiserial"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>

	<xsl:template match="@value[parent::entry[@key='process.operation']]">
		<xsl:attribute name="value">
			<xsl:choose>
				<xsl:when test="not($operation)">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$operation"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>

	<xsl:template match="@value[parent::entry[@key='process.mappingFile']]">
		<xsl:attribute name="value">
			<xsl:choose>
				<xsl:when test="not($mappingfile)">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$mappingfile"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>

	<xsl:template match="@value[parent::entry[@key='dataAccess.type']]">
		<xsl:attribute name="value">
			<xsl:choose>
				<xsl:when test="not($dataaccess)">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$dataaccess"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>

	<xsl:template match="@value[parent::entry[@key='process.lastRunOutputDirectory']]">
		<xsl:attribute name="value">
			<xsl:choose>
				<xsl:when test="not($logdir)">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$logdir"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>

	<xsl:template match="@value[parent::entry[@key='process.statusOutputDirectory']]">
		<xsl:attribute name="value">
			<xsl:choose>
				<xsl:when test="not($logdir)">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$logdir"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>

	<xsl:template match="@value[parent::entry[@key='sfdc.endpoint']]">
		<xsl:attribute name="value">
			<xsl:choose>
				<xsl:when test="not($endpoint)">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$endpoint"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>

	<xsl:template match="@value[parent::entry[@key='sfdc.entity']]">
		<xsl:attribute name="value">
			<xsl:choose>
				<xsl:when test="not($entity)">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$entity"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>

	<xsl:template match="@value[parent::entry[@key='sfdc.extractionSOQL']]">
		<xsl:attribute name="value">
			<xsl:choose>
				<xsl:when test="not($soql)">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$soql"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>

	<xsl:template match="@value[parent::entry[@key='sfdc.password']]">
		<xsl:attribute name="value">
			<xsl:choose>
				<xsl:when test="not($password)">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$password"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>

	<xsl:template match="@value[parent::entry[@key='sfdc.username']]">
		<xsl:attribute name="value">
			<xsl:choose>
				<xsl:when test="not($username)">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$username"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template> -->

</xsl:stylesheet>