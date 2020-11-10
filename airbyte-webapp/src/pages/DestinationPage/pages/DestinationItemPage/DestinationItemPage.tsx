import React from "react";
import { FormattedMessage } from "react-intl";
import styled from "styled-components";
import { useResource } from "rest-hooks";

import PageTitle from "../../../../components/PageTitle";
import useRouter from "../../../../components/hooks/useRouterHook";
import config from "../../../../config";
import ContentCard from "../../../../components/ContentCard";
import EmptyResource from "../../../../components/EmptyResourceBlock";
import ConnectionResource from "../../../../core/resources/Connection";
import { Routes } from "../../../routes";
import Breadcrumbs from "../../../../components/Breadcrumbs";
import DestinationConnectionTable from "./components/DestinationConnectionTable";
import DestinationResource from "../../../../core/resources/Destination";

const Content = styled(ContentCard)`
  margin: 0 32px 0 27px;
`;

const DestinationItemPage: React.FC = () => {
  const { query, history, push } = useRouter();

  const destination = useResource(DestinationResource.detailShape(), {
    // @ts-ignore
    destinationId: query.id
  });

  const { connections } = useResource(ConnectionResource.listShape(), {
    workspaceId: config.ui.workspaceId
  });

  const onClickBack = () =>
    history.length > 2 ? history.goBack() : push(Routes.Destination);

  const breadcrumbsData = [
    {
      name: <FormattedMessage id="admin.destinations" />,
      onClick: onClickBack
    },
    { name: destination.name }
  ];

  const connectionsWithDestination = connections.filter(
    connectionItem => connectionItem.destinationId === destination.destinationId
  );

  return (
    <>
      <PageTitle title={<Breadcrumbs data={breadcrumbsData} />} withLine />
      {connectionsWithDestination.length ? (
        <DestinationConnectionTable connections={connectionsWithDestination} />
      ) : (
        <Content>
          <EmptyResource
            text={<FormattedMessage id="destinations.noSources" />}
            description={
              <FormattedMessage id="destinations.addSourceReplicateData" />
            }
          />
        </Content>
      )}
    </>
  );
};

export default DestinationItemPage;
