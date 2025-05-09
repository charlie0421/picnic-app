import {createClient} from "@/utils/supabase-server-client";
import {Reward, Vote, VoteItem} from "@/types/interfaces";

// 서버 컴포넌트에서 투표 상세 정보 가져오기
export const getServerVoteById = async (id: number): Promise<Vote | null> => {
    try {
        const supabase = await createClient();
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
        console.error(
            "서버: 투표 상세 정보를 가져오는 중 오류가 발생했습니다:",
            error,
        );
        return null;
    }
};

// 서버 컴포넌트에서 투표 항목 데이터 가져오기
export const getServerVoteItems = async (
    voteId: number,
): Promise<VoteItem[]> => {
    try {
        const supabase = await createClient();
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

        return voteItemsData.map((item: any) => ({
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
        console.error(
            "서버: 투표 항목 데이터를 가져오는 중 오류가 발생했습니다:",
            error,
        );
        return [];
    }
};

// 서버 컴포넌트에서 투표 리워드 데이터 가져오기
export const getServerVoteRewards = async (
    voteId: number,
): Promise<Reward[]> => {
    try {
        const supabase = await createClient();
        const { data: rewardsData, error: rewardsError } = await supabase
            .from("vote_reward")
            .select(`
        reward:reward_id (*)
      `)
            .eq("vote_id", voteId);

        if (rewardsError) throw rewardsError;
        if (!rewardsData || rewardsData.length === 0) return [];

        return rewardsData
            .map((item: any) => item.reward)
            .filter(Boolean);
    } catch (error) {
        console.error(
            "서버: 투표 리워드 데이터를 가져오는 중 오류가 발생했습니다:",
            error,
        );
        return [];
    }
};

// 투표 데이터, 아이템, 리워드를 한 번에 가져오는 함수
export const getServerVoteData = async (id: number) => {
    try {
        const [vote, voteItems, rewards] = await Promise.all([
            getServerVoteById(id),
            getServerVoteItems(id),
            getServerVoteRewards(id),
        ]);

        return { vote, voteItems, rewards };
    } catch (error) {
        console.error(
            "서버: 투표 데이터를 가져오는 중 오류가 발생했습니다:",
            error,
        );
        return { vote: null, voteItems: [], rewards: [] };
    }
};
