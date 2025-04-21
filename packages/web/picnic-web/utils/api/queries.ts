import { supabase } from "./supabase";
import { Banner, Media, Reward, Vote, VoteItem } from "@/types/interfaces";

// 투표 데이터 가져오기
export const getVotes = async (
  sortBy: "votes" | "recent" = "votes",
): Promise<Vote[]> => {
  try {
    const now = new Date();
    const currentTime = now.toISOString();

    const { data: voteData, error: voteError } = await supabase
      .from("vote")
      .select(`
        *,
        vote_item (
          *,
          artist (
            *,
            artist_group (*)
          )
        ),
        vote_reward (
          reward_id,
          reward:reward_id (*)
        )
      `)
      .is("deleted_at", null)
      .order("created_at", { ascending: false });

    if (voteError) throw voteError;
    if (!voteData || voteData.length === 0) return [];

    return voteData.map((vote) => ({
      ...vote,
      deletedAt: vote.deleted_at,
      startAt: vote.start_at,
      stopAt: vote.stop_at,
      createdAt: vote.created_at,
      updatedAt: vote.updated_at,
      mainImage: vote.main_image,
      resultImage: vote.result_image,
      waitImage: vote.wait_image,
      voteCategory: vote.vote_category,
      voteContent: vote.vote_content,
      voteSubCategory: vote.vote_sub_category,
      visibleAt: vote.visible_at,
      voteItems: vote.vote_item
        ? vote.vote_item.map((item: any) => ({
          ...item,
          deletedAt: item.deleted_at,
          createdAt: item.created_at,
          updatedAt: item.updated_at,
          voteId: item.vote_id,
          artistId: item.artist_id,
          groupId: item.group_id,
          voteTotal: item.vote_total,
          artist: item.artist,
        }))
        : [],
      rewards: vote.vote_reward
        ? vote.vote_reward.map((vr: any) => vr.reward).filter(Boolean)
        : [],
      title: vote.title || "제목 없음",
    }));
  } catch (error) {
    console.error("투표 데이터를 가져오는 중 오류가 발생했습니다:", error);
    return [];
  }
};

// 리워드 데이터 가져오기
export const getRewards = async (limit?: number): Promise<Reward[]> => {
  try {
    let query = supabase
      .from("reward")
      .select("*")
      .is("deleted_at", null)
      .order("order", { ascending: true });

    if (limit) {
      query = query.limit(limit);
    }

    const { data: rewardData, error: rewardError } = await query;

    if (rewardError) throw rewardError;
    if (!rewardData || rewardData.length === 0) return [];

    return rewardData.map((reward) => ({
      ...reward,
      deletedAt: reward.deleted_at,
      createdAt: reward.created_at,
      updatedAt: reward.updated_at,
      locationImages: reward.location_images,
      overviewImages: reward.overview_images,
      sizeGuide: reward.size_guide,
      sizeGuideImages: reward.size_guide_images,
    }));
  } catch (error) {
    console.error("리워드 데이터를 가져오는 중 오류가 발생했습니다:", error);
    return [];
  }
};

// 배너 데이터 가져오기
export const getBanners = async (): Promise<Banner[]> => {
  try {
    const now = new Date();
    const currentTime = now.toISOString();

    const { data: bannerData, error: bannerError } = await supabase
      .from("banner")
      .select("*")
      .is("deleted_at", null)
      .order("order", { ascending: true })
      .lte("start_at", currentTime)
      .gt("end_at", currentTime)
      .limit(10);

    if (bannerError) throw bannerError;
    if (!bannerData || bannerData.length === 0) return [];

    return bannerData.map((banner) => ({
      ...banner,
      deletedAt: banner.deleted_at,
      createdAt: banner.created_at,
      updatedAt: banner.updated_at,
      startAt: banner.start_at,
      endAt: banner.end_at,
      celebId: banner.celeb_id,
    }));
  } catch (error) {
    console.error("배너 데이터를 가져오는 중 오류가 발생했습니다:", error);
    return [];
  }
};

// 리워드 상세 정보 가져오기
export const getRewardById = async (id: string): Promise<Reward | null> => {
  try {
    const { data: rewardData, error: rewardError } = await supabase
      .from("reward")
      .select("*")
      .eq("id", id)
      .is("deleted_at", null)
      .single();

    if (rewardError) throw rewardError;
    if (!rewardData) return null;

    return {
      ...rewardData,
      deletedAt: rewardData.deleted_at,
      createdAt: rewardData.created_at,
      updatedAt: rewardData.updated_at,
      locationImages: rewardData.location_images,
      overviewImages: rewardData.overview_images,
      sizeGuide: rewardData.size_guide,
      sizeGuideImages: rewardData.size_guide_images,
    };
  } catch (error) {
    console.error("리워드 상세 정보를 가져오는 중 오류가 발생했습니다:", error);
    return null;
  }
};

// 미디어 데이터 가져오기
export const getMedias = async (): Promise<Media[]> => {
  try {
    const { data: mediaData, error: mediaError } = await supabase
      .from("media")
      .select("*")
      .is("deleted_at", null)
      .order("created_at", { ascending: false });

    if (mediaError) throw mediaError;
    if (!mediaData || mediaData.length === 0) return [];

    // 스네이크 케이스에서 캐멀 케이스로 필드 변환
    return mediaData.map((media) => ({
      id: media.id,
      createdAt: media.created_at,
      updatedAt: media.updated_at,
      deletedAt: media.deleted_at,
      thumbnailUrl: media.thumbnail_url,
      videoUrl: media.video_url,
      videoId: media.video_id,
      title: media.title,
    }));
  } catch (error) {
    console.error("미디어 데이터를 가져오는 중 오류가 발생했습니다:", error);
    return [];
  }
};

// 투표 상세 정보 가져오기
export const getVoteById = async (id: number): Promise<Vote | null> => {
  try {
    const { data: voteData, error: voteError } = await supabase
      .from("vote")
      .select(`
        *
      `)
      .eq("id", id)
      .is("deleted_at", null)
      .single();

    if (voteError) throw voteError;
    if (!voteData) return null;

    return {
      ...voteData,
      deletedAt: voteData.deleted_at,
      startAt: voteData.start_at,
      stopAt: voteData.stop_at,
      createdAt: voteData.created_at,
      updatedAt: voteData.updated_at,
      mainImage: voteData.main_image,
      resultImage: voteData.result_image,
      waitImage: voteData.wait_image,
      voteCategory: voteData.vote_category,
      voteContent: voteData.vote_content,
      voteSubCategory: voteData.vote_sub_category,
      visibleAt: voteData.visible_at,
      title: voteData.title || "제목 없음",
    };
  } catch (error) {
    console.error("투표 상세 정보를 가져오는 중 오류가 발생했습니다:", error);
    return null;
  }
};

// 투표 항목 데이터 가져오기
export const getVoteItems = async (voteId: number): Promise<VoteItem[]> => {
  try {
    const { data: voteItemsData, error: voteItemsError } = await supabase
      .from("vote_item")
      .select(`
        *,
        artist (
          *,
          artist_group (
            *
          )
        )
      `)
      .eq("vote_id", voteId)
      .is("deleted_at", null);

    if (voteItemsError) throw voteItemsError;
    if (!voteItemsData || voteItemsData.length === 0) return [];

    return voteItemsData.map((item) => ({
      ...item,
      deletedAt: item.deleted_at,
      createdAt: item.created_at,
      updatedAt: item.updated_at,
      voteId: item.vote_id,
      artistId: item.artist_id,
      groupId: item.group_id,
      voteTotal: item.vote_total,
      artist: item.artist,
    }));
  } catch (error) {
    console.error("투표 항목 데이터를 가져오는 중 오류가 발생했습니다:", error);
    return [];
  }
};

// 투표 보상 데이터 가져오기
export const getVoteRewards = async (voteId: number): Promise<Reward[]> => {
  try {
    const { data: voteRewardData, error: voteRewardError } = await supabase
      .from("vote_reward")
      .select(`
        reward_id
      `)
      .eq("vote_id", voteId);

    if (voteRewardError) throw voteRewardError;
    if (!voteRewardData || voteRewardData.length === 0) return [];

    const rewardIds = voteRewardData.map((vr) => vr.reward_id);

    const { data: rewardData, error: rewardError } = await supabase
      .from("reward")
      .select("*")
      .in("id", rewardIds)
      .is("deleted_at", null);

    if (rewardError) throw rewardError;
    if (!rewardData || rewardData.length === 0) return [];

    return rewardData.map((reward) => ({
      ...reward,
      deletedAt: reward.deleted_at,
      createdAt: reward.created_at,
      updatedAt: reward.updated_at,
      locationImages: reward.location_images,
      overviewImages: reward.overview_images,
      sizeGuide: reward.size_guide,
      sizeGuideImages: reward.size_guide_images,
    }));
  } catch (error) {
    console.error("투표 보상 데이터를 가져오는 중 오류가 발생했습니다:", error);
    return [];
  }
};
