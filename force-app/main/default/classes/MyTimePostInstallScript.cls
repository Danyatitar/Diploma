global class MyTimePostInstallScript implements InstallHandler {
    global void onInstall(InstallContext context) {
        scheduleJobsIfNotExists();
    }

    @TestVisible
    private static void scheduleJobsIfNotExists() {
        String salaryJobName = 'Daily_Salary_Scheduler_Job';
        String resetJobName = 'Daily_Annual_Reset_Job';

        List<CronTrigger> existingJobs = [
            SELECT Id, CronJobDetail.Name FROM CronTrigger
            WHERE CronJobDetail.Name IN :new List<String>{salaryJobName, resetJobName}
        ];

        Set<String> existingJobNames = new Set<String>();
        for (CronTrigger ct : existingJobs) {
            existingJobNames.add(ct.CronJobDetail.Name);
        }

        if (!existingJobNames.contains(salaryJobName)) {
            String cronExpr = '0 0 10 * * ?'; // 10 AM daily
            System.schedule(salaryJobName, cronExpr, new SalaryDetailsScheduler());
        }

        if (!existingJobNames.contains(resetJobName)) {
            String cronExpr = '0 0 1 * * ?'; // 1 AM daily
            System.schedule(resetJobName, cronExpr, new AnnualUserResetScheduler());
        }
    }
}