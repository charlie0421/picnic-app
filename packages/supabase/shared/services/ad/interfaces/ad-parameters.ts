export interface AdMobParameters {
  key_id: string;
  user_id: string;
  reward_amount: number;
  reward_type: string;
  transaction_id: string;
  signature: string;
  platform: string;
  ad_network: string;
  app_key?: string;
  pub_key?: number;
  app_title?: string;
  menu_category?: string;
}

export interface PangleParameters {
  user_id: string;
  reward_amount: number;
  reward_type: string;
  transaction_id: string;
  signature: string;
  platform: string;
}

export interface PincruxParameters {
  user_id: string;
  reward_amount: number;
  reward_type: string;
  transaction_id: string;
  signature: string;
  platform: string;
  ad_network: string;
  appkey: string;
  pubkey: number;
  usrkey: string;
  app_title: string;
  coin: string;
  transid: string;
  resign_flag: string;
  commission: string;
  menu_category1: string;
  menu_category2?: string;
  menu_category3?: string;
  menu_category4?: string;
  menu_category5?: string;
  ad_type?: string;
  ad_unit_id?: string;
  ad_unit_name?: string;
}

export interface TapjoyParameters {
  user_id: string;
  platform: string;
  currency: number;
  snuid: string;
  id: string;
  mac_address: string;
  verifier: string;
  ad_network: string;
}

export interface UnityAdsParameters {
  user_id: string;
  reward_amount: number;
  reward_type: string;
  transaction_id: string;
  signature: string;
  platform: string;
  ad_network: string;
  placement_id: string;
  placement_name: string;
  placement_type: string;
  placement_state: string;
  placement_reward_amount: number;
  placement_reward_item_key: string;
  placement_reward_item_name: string;
  placement_reward_item_picture: string;
  placement_reward_item_multiplier: number;
  placement_reward_item_extra_data?: Record<string, unknown>;
  placement_reward_item_decision_point?: string;
  placement_reward_item_decision_point_data?: Record<string, unknown>;
}

export interface AppLovinParameters {
  user_id: string;
  reward_amount: number;
  reward_type: string;
  transaction_id: string;
  signature: string;
  platform: string;
  ad_network: string;
  ad_unit_id: string;
  ad_unit_name: string;
  ad_type: string;
  ad_network_id?: string;
  ad_network_name?: string;
  ad_network_placement_id?: string;
  ad_network_creative_id?: string;
  ad_network_impression_id?: string;
  ad_network_click_id?: string;
  ad_network_request_id?: string;
  ad_network_response_id?: string;
  ad_network_revenue?: number;
  ad_network_currency?: string;
  ad_network_zone_id?: string;
  ad_network_zone_name?: string;
}

export interface IronSourceParameters {
  user_id: string;
  reward_amount: number;
  reward_type: string;
  transaction_id: string;
  signature: string;
  platform: string;
  ad_network: string;
  instance_id: string;
  instance_name: string;
  instance_type: string;
  ad_network_id?: string;
  ad_network_name?: string;
  ad_network_placement_id?: string;
  ad_network_creative_id?: string;
  ad_network_impression_id?: string;
  ad_network_click_id?: string;
  ad_network_request_id?: string;
  ad_network_response_id?: string;
  ad_network_revenue?: number;
  ad_network_currency?: string;
  ad_network_zone_id?: string;
  ad_network_zone_name?: string;
  ad_network_segment_id?: string;
  ad_network_segment_name?: string;
}

export interface AdCallbackParams {
  user_id: string;
  reward_amount: number;
  reward_type: string;
  transaction_id: string;
  signature: string;
  platform: string;
  ad_network: string;
}
