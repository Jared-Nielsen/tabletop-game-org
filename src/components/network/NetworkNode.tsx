import { SponsorNode } from "./SponsorNode";
import { InviteNode } from "./InviteNode";
import { PlayerNode } from "./PlayerNode";
import { PendingNode } from "./PendingNode";

interface NetworkNodeProps {
  node: {
    id: string;
    alias: string;
    children: any[];
    relationshipId?: string;
  };
  activeSponsor: { uplineId: string; uplineUsername: string } | null;
  adminProfiles: { id: string; username: string }[];
  onSponsorRequest: (adminProfileId: string) => void;
  onInviteCreated?: (invite: any) => void;
  hasPendingRequest?: boolean;
  onStatusUpdate?: () => void;
}

export const NetworkNode = ({ 
  node, 
  activeSponsor, 
  adminProfiles, 
  onSponsorRequest,
  onInviteCreated,
  hasPendingRequest,
  onStatusUpdate 
}: NetworkNodeProps) => {
  const renderNode = () => {
    switch (node.id) {
      case "sponsor":
        return (
          <SponsorNode
            activeSponsor={activeSponsor}
            adminProfiles={adminProfiles}
            onSponsorRequest={onSponsorRequest}
            hasPendingRequest={hasPendingRequest}
          />
        );
      case "left":
        return <InviteNode onInviteCreated={onInviteCreated} />;
      case "root":
        return <PlayerNode isRoot />;
      case "pending":
        return <PendingNode relationshipId={node.relationshipId!} onStatusUpdate={onStatusUpdate!} />;
      default:
        return <PlayerNode isDownline alias={node.alias} />;
    }
  };

  return (
    <div className="flex flex-col items-center relative">
      {renderNode()}
      {node.children.length > 0 && (
        <>
          <div className="w-[2px] h-8 border-l-2 border-dashed border-gray-300" />
          <div className="flex gap-8 mt-4 relative">
            {node.children.length > 1 && (
              <div 
                className="absolute top-0 left-1/2 transform -translate-x-1/2 -translate-y-4 h-[2px] border-t-2 border-dashed border-gray-300" 
                style={{ width: 'calc(100% - 2rem)' }} 
              />
            )}
            {node.children.map((child) => (
              <NetworkNode
                key={child.id === "pending" ? `invite_${child.relationshipId}` : child.id}
                node={child}
                activeSponsor={activeSponsor}
                adminProfiles={adminProfiles}
                onSponsorRequest={onSponsorRequest}
                onInviteCreated={onInviteCreated}
                hasPendingRequest={hasPendingRequest}
                onStatusUpdate={onStatusUpdate}
              />
            ))}
          </div>
        </>
      )}
    </div>
  );
};