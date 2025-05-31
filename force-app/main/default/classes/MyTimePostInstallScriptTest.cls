@isTest
private class MyTimePostInstallScriptTest {

    @isTest
    static void testScheduleJobsIfNotExists() {
        Test.startTest();
        MyTimePostInstallScript.scheduleJobsIfNotExists();
        Test.stopTest();

        List<CronTrigger> scheduledJobs = [
            SELECT CronJobDetail.Name FROM CronTrigger 
            WHERE CronJobDetail.Name IN ('Daily_Salary_Scheduler_Job', 'Daily_Annual_Reset_Job')
        ];

        Set<String> jobNames = new Set<String>();
        for (CronTrigger job : scheduledJobs) {
            jobNames.add(job.CronJobDetail.Name);
        }

        System.assert(jobNames.contains('Daily_Salary_Scheduler_Job'), 'Salary job should be scheduled');
        System.assert(jobNames.contains('Daily_Annual_Reset_Job'), 'Reset job should be scheduled');
    }
}