Awsm::KubeyWorkshopSetupRequest.all(successful: true)

r = Awsm::KubeyWorkshopSetupRequest.all(successful: true).detect{|r| r.data["assigned"].nil?}

attendee = "jacob+k8sworkshop1@engineyard.com"
Awsm::Membership.create(
  :email     => attendee,
  :requester => User.by_email("jburkhart@engineyard.com"),
  :account   => r.account,
  :role      => 'admin',
)
r.data["assigned"] = attendee
r.save_data!

