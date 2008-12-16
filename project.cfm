<cfsetting enablecfoutputonly="true">

<cfparam name="url.p" default="">
<cfif session.user.admin>
	<cfset project = application.project.get(projectID=url.p)>
<cfelse>
	<cfset project = application.project.get(session.user.userid,url.p)>
</cfif>
<cfset projectUsers = application.project.projectUsers(url.p,'0','lastLogin desc')>
<cfif project.mstones gt 0>
	<cfset milestones_overdue = application.milestone.get(url.p,'','overdue')>
	<cfset milestones_upcoming = application.milestone.get(url.p,'','upcoming','1')>
</cfif>
<cfif project.issues gt 0>
	<cfset issues = application.issue.get(url.p,'','New|Accepted')>
</cfif>
<cfset activity = application.activity.get(url.p,'','true')>

<!--- Loads header/footer --->
<cfmodule template="#application.settings.mapping#/tags/layout.cfm" templatename="main" title="#project.name# &raquo; Overview" project="#project.name#" projectid="#url.p#" svnurl="#project.svnurl#">

<cfsavecontent variable="js">
<cfoutput>
<script type='text/javascript'>
$(document).ready(function(){
	<cfif project.issues gt 0 and issues.recordCount>
	$('##issues').tablesorter({
			cssHeader: 'theader',
			sortList: [[0,0]],
			headers: { 3: { sorter:'statuses' }, 6: { sorter:'usMonthOnlyDate' }, 7: { sorter:'usMonthOnlyDate' } },
			widgets: ['zebra']  
	});
	</cfif>
	<cfif activity.recordCount>
	$('##activity').tablesorter({
			cssHeader: 'theader',
			sortList: [[4,1]],
			headers: { 4: { sorter:'usLongDate' } },
			widgets: ['zebra']
	});
	$('table##activity').Scrollable(250,'');
	</cfif>
});
</script>
</cfoutput>
</cfsavecontent>

<cfhtmlhead text="#js#">

<cfoutput>
<div id="container">
<cfif project.recordCount>
	<!--- left column --->
	<div class="left">
		<div class="main">

			<div class="header">
				<span class="rightmenu">
					<cfif project.msgs gt 1>
					<a href="editMessage.cfm?p=#url.p#" class="add">Message</a>
					</cfif>
					<cfif project.todos gt 1>
						| <a href="editTodolist.cfm?p=#url.p#" class="add">To-do list</a>
					</cfif>
					<cfif project.mstones gt 1>
						| <a href="editMilestone.cfm?p=#url.p#" class="add">Milestone</a>
					</cfif>
					<cfif project.issues gt 1>
						| <a href="editIssue.cfm?p=#url.p#" class="add">Issue</a>
					</cfif>
				</span>					
				
				<h2 class="overview">Project overview</h2>
			</div>
			<div class="content">
				<div class="wrapper">
				
				<cfif project.display><div class="fs12 mb20">#project.description#</div></cfif>
				
				<cfif project.mstones gt 0 or project.issues gt 0>
					<!--- due in next 14 days calendar --->
					<cfif project.mstones gt 0>
						<cfquery name="ms_next_14" dbtype="query">
							select * from milestones_upcoming where dueDate <= 
							<cfqueryparam value="#CreateODBCDate(DateAdd("d",13,Now()))#" cfsqltype="CF_SQL_DATE" />
						</cfquery>
					</cfif>
					<cfif project.issues gt 0>
						<cfquery name="issues_next_14" dbtype="query">
							select * from issues where dueDate <= 
							<cfqueryparam value="#CreateODBCDate(DateAdd("d",13,Now()))#" cfsqltype="CF_SQL_DATE" />
						</cfquery>
					</cfif>
					<cfif (project.mstones gt 0 and ms_next_14.recordCount) or (project.issues gt 0 and issues_next_14.recordCount)>
					<div class="mb5 b" style="border-bottom:1px solid ##000;">Due in the next 14 days</div>
					<cfset theDay = dayOfWeek(now())>
					<table border="0" cellpadding="0" cellspacing="1" width="100%" id="milestone_cal">
						<tr>
						<cfloop index="i" from="0" to="6">
							<th>#Left(dayOfWeekAsString(theDay),3)#</th>
							<cfset theDay = theDay + 1>
							<cfif theDay eq 8>
								<cfset theDay = 1>
							</cfif>
						</cfloop>
						</tr>
						
						<cfloop index="i" from="0" to="13">
							<cfif i mod 7 eq 0><tr></cfif>
								<cfif project.mstones gt 0>
									<cfquery name="todays_ms" dbtype="query">
										select milestoneid,name from milestones_upcoming where dueDate = 
										<cfqueryparam value="#CreateODBCDate(DateAdd("d",i,Now()))#" cfsqltype="CF_SQL_DATE" />
									</cfquery>
								</cfif>
								<cfif project.issues gt 0>
									<cfquery name="todays_issues" dbtype="query">
										select issueid,issue from issues where dueDate = 
										<cfqueryparam value="#CreateODBCDate(DateAdd("d",i,Now()))#" cfsqltype="CF_SQL_DATE" />
									</cfquery>
								</cfif>
								<cfif i eq 0>
									<td class="today"><span class="b">TODAY</span>
								<cfelse>
									<td<cfif (project.mstones gt 0 and todays_ms.recordCount) or (project.issues gt 0 and todays_issues.recordCount gt 0)> class="active"</cfif>><cfif i eq 1 or DatePart("d",DateAdd("d",i,Now())) eq 1>#Left(MonthAsString(Month(DateAdd("d",i,Now()))),3)#</cfif>
									#DateFormat(DateAdd("d",i,Now()),"d")#
								</cfif>
								<ul class="cal_ms">
								<cfif project.mstones gt 0 and todays_ms.recordCount>
									<cfloop query="todays_ms">
										<li><a href="milestone.cfm?p=#url.p#&m=#milestoneID#">#name#</a> (milestone)</li>
									</cfloop>
								</cfif>
								<cfif project.issues gt 0 and todays_issues.recordCount>
									<cfloop query="todays_issues">
										<li><a href="issue.cfm?p=#url.p#&i=#issueID#">#issue#</a> (issue)</li>
									</cfloop>
								</cfif>
								</ul>
							</td>
							<cfif i mod 7 eq 6></tr></cfif>
						</cfloop>
					</table>
					<br />
					</cfif>

					<cfif project.mstones gt 0 and milestones_overdue.recordCount>
						<div class="overdue">
						<div class="mb5 b" style="color:##f00;border-bottom:1px solid ##f00;">Late Milestones</div>
						<ul class="nobullet">
							<cfloop query="milestones_overdue">
							<cfset daysDiff = DateDiff("d",dueDate,Now())>
							<li><span class="b" style="color:##f00;"><cfif daysDiff eq 0>Today<cfelseif daysDiff eq 1>Yesterday<cfelse>#daysDiff# days ago</cfif>:</span> 
							<a href="milestone.cfm?p=#projectID#&m=#milestoneID#">#name#</a>
							<cfif compare(lastName,'')><span style="font-size:.9em;">(#firstName# #lastName# is responsible)</span></cfif>
							</li>
							</cfloop>
						</ul>
						</div><br />
					</cfif>

					<cfif milestones_upcoming.recordCount>
					<div class="mb5 b" style="border-bottom:1px solid ##000;">
						<span style="float:right;font-size:.75em;"><a href="##" onclick="upcoming_milestones('#url.p#','1');$(this).addClass('subactive');$('##threem').removeClass('subactive');$('##all').removeClass('subactive');return false;" class="sublink subactive" id="onem">1 month</a> | <a href="##" onclick="upcoming_milestones('#url.p#','3');$('##onem').removeClass('subactive');$(this).addClass('subactive');$('##all').removeClass('subactive');return false;" class="sublink" id="threem">3 months</a> | <a href="##" onclick="upcoming_milestones('#url.p#','');$('##onem').removeClass('subactive');$('##threem').removeClass('subactive');$(this).addClass('subactive');return false;" class="sublink" id="all">All</a></span>
						Upcoming Milestones</div>	
					<ul class="nobullet" id="upcoming_milestones">
						<cfloop query="milestones_upcoming">
							<cfset daysDiff = DateDiff("d",CreateDate(year(Now()),month(Now()),day(Now())),dueDate)>
						<li><span class="b"><cfif daysDiff eq 0>Today<cfelseif daysDiff eq 1>Tomorrow<cfelse>#daysDiff# days away</cfif>:</span> 
							<a href="milestone.cfm?p=#projectID#&m=#milestoneID#">#name#</a>
							<cfif compare(lastName,'')><span style="font-size:.9em;">(#firstName# #lastName# is responsible)</span></cfif>
						</li>
						</cfloop>
					</ul><br />
					</cfif>
				</cfif>

				<cfif project.issues gt 0 and issues.recordCount>
					<div style="border:1px solid ##ddd;" class="mb20">
					<table class="activity full tablesorter" id="issues">
					<caption class="plain">Open Issues</caption>
					<thead>
						<tr>
							<th>ID</th>
							<th>Type</th>
							<th>Severity</th>
							<th>Issue</th>
							<th>Status</th>
							<th>Assigned To</th>
							<th>Reported</th>
							<th>Updated</th>
							<th>Due</th>
						</tr>
					</thead>
					<tbody>
						<cfset thisRow = 1>
						<cfloop query="issues">
						<tr>
							<td><a href="issue.cfm?p=#url.p#&i=#issueID#">#shortID#</a></td>
							<td>#type#</td>
							<td>#severity#</td>
							<td><a href="issue.cfm?p=#url.p#&i=#issueID#">#issue#</a></td>
							<td>#status#</td>
							<td>#assignedFirstName# #assignedLastName#</td>
							<td>#DateFormat(created,"mmm d")#</td>
							<td>#DateFormat(updated,"mmm d")#</td>
							<td>#DateFormat(dueDate,"mmm d")#</td>
						</tr>
						<cfset thisRow = thisRow + 1>
						</cfloop>
					</tbody>
					</table>
					</div>
				</cfif>
				
				<cfif activity.recordCount>
				<div style="border:1px solid ##ddd;">
				<div style="background-color:##eee;font-weight:bold;font-size:1.2em;padding:5px;margin-bottom:1px;">
				<span class="feedlink"><a href="rss.cfm?u=#session.user.userID#&p=#url.p#&type=act" class="feed">RSS Feed</a></span>Recent Activity
				</div>
				
				<table class="activity full tablesorter" id="activity">
					<thead>
						<tr>
							<th>Type</th>
							<th>Title</th>
							<th>Action</th>
							<th>User</th>
							<th>Timestamp</th>
						</tr>
					</thead>
					<tbody>
					<cfset thisRow = 1>
					
					<cfloop query="activity">						
						<cfif not ((not compareNoCase(type,'issue') and project.issues eq 0) or (not compareNoCase(type,'message') and project.msgs eq 0) or (not compareNoCase(type,'milestone') and project.mstones eq 0) or (not compareNoCase(type,'to-do list') and project.todos eq 0) or (not compareNoCase(type,'file') and project.files eq 0))>
						<tr><td><div class="catbox
							<cfswitch expression="#type#">
								<cfcase value="Issue">issue">Issue</cfcase>		
								<cfcase value="Message">message">Message</cfcase>
								<cfcase value="Milestone">milestone">Milestone</cfcase>
								<cfcase value="To-Do List">todolist">To-Do List</cfcase>
								<cfcase value="File">file">File</cfcase>
								<cfcase value="Project">project">Project</cfcase>
								<cfcase value="Screenshot">screenshot">Screenshot</cfcase>
								<cfdefaultcase>>#type#</cfdefaultcase>
							</cfswitch>	
						</div></td>
						<td><cfswitch expression="#type#">
								<cfcase value="Issue"><a href="issue.cfm?p=#url.p#&i=#id#">#name#</a></cfcase>		
								<cfcase value="Message"><a href="message.cfm?p=#url.p#&m=#id#">#name#</a></cfcase>
								<cfcase value="Milestone"><a href="milestones.cfm?p=#url.p#&m=#id#">#name#</a></cfcase>
								<cfcase value="To-Do List"><a href="todos.cfm?p=#url.p#&t=#id#">#name#</a></cfcase>
								<cfcase value="File"><a href="files.cfm?p=#url.p#&f=#id#">#name#</a></cfcase>
								<cfcase value="Project"><a href="project.cfm?p=#url.p#">#name#</a></cfcase>
								<cfcase value="Screenshot"><a href="issue.cfm?p=#url.p#&i=#id###screen">#name#</a></cfcase>
								<cfdefaultcase>#name#</cfdefaultcase>
							</cfswitch>
							</td>
						<td class="g">#activity# by</td>
						<td>#firstName# #lastName#</td>
						<td>#DateFormat(stamp,"mmm d, yyyy")# #TimeFormat(stamp,"h:mm tt")#</td>
						</tr>
						<cfset thisRow = thisRow + 1>
						</cfif>
						
					</cfloop>
					</tbody>
				</table>
				</div>
				<cfelse>
					<div class="warn">There is no recent activity.</div>
				</cfif>
			 		
			 		
			 	</div>
			</div>
			
		</div>
		<div class="bottom">&nbsp;</div>
		<div class="footer">
			<cfinclude template="footer.cfm">
		</div>	  
	</div>

	<!--- right column --->
	<div class="right">
	
		<cfif compare(project.clientID,'')>
			<div class="header"><h3>Client</h3></div>
			<div class="content">
				<ul>
					<li>#project.clientName#</li>
				</ul>
			</div>
		</cfif>
	
		<div class="header"><h3>Project Owner</h3></div>
		<div class="content">
			<ul>
				<li>#project.ownerFirstName# #project.ownerLastName#</li>
			</ul>
		</div>
	
		<div class="header"><h3>People on this project</h3></div>
		<div class="content">
			<ul class="people">
				<cfloop query="projectUsers">
				<li><div class="b">#firstName# #lastName#<cfif admin> (admin)</cfif></div>
				<div style="font-weight:normal;font-size:.9em;color:##666;"><cfif compare(userID,session.user.userID)><cfif isDate(lastLogin)>Last login 
					<cfif DateDiff("n",lastLogin,Now()) lt 60>
						#DateDiff("n",lastLogin,Now())# minutes
					<cfelseif DateDiff("h",lastLogin,Now()) lt 24>
						#DateDiff("h",lastLogin,Now())# hours
					<cfelseif DateDiff("d",lastLogin,Now()) lt 31>
						#DateDiff("d",lastLogin,Now())# days
					<cfelseif DateDiff("m",lastLogin,Now()) lt 12>
						#DateDiff("m",lastLogin,Now())# months
					<cfelse>
						#DateDiff("y",lastLogin,Now())# year<cfif DateDiff("y",lastLogin,Now()) gt 1>s</cfif>
					</cfif> ago
					<cfelse>Never logged in</cfif><cfelse>Currently logged in</cfif></div></li>
				</cfloop>
			</ul>
		</div>
	</div>
<cfelse>
	<img src="./images/alert.gif" height="16" width="16" alt="Alert!" style="vertical-align:middle;" /> Project Not Found.
</cfif>
</div>
</cfoutput>

</cfmodule>

<cfsetting enablecfoutputonly="false">