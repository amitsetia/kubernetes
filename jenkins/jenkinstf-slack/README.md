Jenkins integration notification with slack.
Today we will learn how to send success, error notification to slack through the Jenkins CI job and from the Jenkinsfile(Declarative Pipeline.)

Installation of Slack Notification Plugin:

1. In your Jenkins dashboard, click on Manage Jenkins from the left navigation.
2. Navigate to Manage Plugins.
3. Click on the tab name as Available.
4. Search for Slack Notification
5. Check the box next to install


Jenkins CI App installation in Slack

1. Go to Slack App Directory and search for Jenkins CI
2. Click on the Add to Slack button
3. Now select the channel and click on the Add Jenkins CI Integration
4. Copy the Token from the Jenkins CI Page and Click on the Save Setting button at the bottom


Slack notification plugin configuration in Jenkins

In the first step, we have installed the Slack notification plugin. now time to configure the plugin.

Please follow the below steps

        Click on Manage Jenkins again in the left navigation and then click to Configure system.
        Find the Global Slack notifier settings section and add the following values
        a. Team subdomain: <Your team domain>
        b. Integration token credential ID: <Paste the token which we got from step 2>
        c. The other fields are optional. You can click on the question mark icons next to them for more information.
        d. Press Save once you’ve finished. 
Click on the Test connection button to test the notification in the slack channel. Below is the sample notification


